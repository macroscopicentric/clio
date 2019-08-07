#!/usr/bin/env ruby
require 'json'
require 'csv'
require 'twitter'
require 'date'

class SocialMediaBackup
	class Twitter
		# TODO: update twitter archive methods to deal with new twitter archive style
		# TODO: just use the twitter gem Tweet class to handle tweets in memory you dingdong
		# TODO: following, followers, likes, and dms?

		MEDIA_TYPES = {
			'Twitter::Media::AnimatedGif' => 'animated_gif',
			'Twitter::Media::Photo' => 'photo',
			'Twitter::Media::Video' => 'video'
		}

		TWEET_COUNT_INCREMENTER = 100000000000000

		ARCHIVE_FILE_PREFIX = 'window.YTD.tweet.part0 = '

		attr_accessor :tweets

		def initialize(config=nil, backup_file=nil)
			@client = configure_client(config) if config
			@screen_name = config['screen_name'] if config
			@backup_file = backup_file
			# @tweets is a hash where each key is a tweet id and the value is
			# the full content of the tweet as a hash.
			@tweets = {}
			@newest_tweet_id = nil
			@oldest_tweet_id = nil
		end

		def configure_client(config)
			::Twitter::REST::Client.new do |c|
				c.consumer_key = config['consumer_key']
				c.consumer_secret = config['consumer_secret']
				c.access_token = config['access_token']
				c.access_token_secret = config['access_token_secret']
			end
		end

		# Imports CSV tweet backup downloaded from Twitter. Twitter's API
		# only allows you to GET the most recent 3200 tweets, so anything older
		# than that needs to be downloaded manually from Twitter through the
		# GUI and then imported via this method.
		def import_and_merge_twitter_archive(archive_folder)
			imported_tweets = self.import_twitter_archive(file_path)
			formatted_tweets = self.format_all_imported_tweets(imported_tweets)
			self.merge_tweets(formatted_tweets)
		end

		# Import tweets from an archive downloaded from Twitter. See
		# https://help.twitter.com/en/managing-your-account/accessing-your-twitter-data
		# for more information on how to download your own archive.
		# The files are almost perfect JSON except for a weird JS prefix,
		# so let's remove that and then actually JSONify the tweets.
		def import_twitter_archive(file_path)
			return JSON.load(IO.read(file_path).remove_prefix(ARCHIVE_FILE_PREFIX))
		end

		# Bulk format tweets downloaded via Twitter's archive action.
		def format_all_imported_tweets(imported_tweets)
			return imported_tweets.map { |tweet| self.format_csv_tweet(tweet) }
		end

		# Bulk format tweets downloaded via the Twitter API gem.
		def format_all_api_tweets(downloaded_tweets)
			return downloaded_tweets.map { |tweet| self.format_api_tweet(tweet) }
		end

		# Expects an array of hashes.
		def merge_tweets(imported_tweets)
			imported_tweets.each do |imported_tweet|
				id = imported_tweet[:id]
				@tweets[id] = imported_tweet unless self.tweet_in_tweets?(id)
			end
		end

		def tweet_in_tweets?(tweet_id)
			return @tweets.key?(tweet_id)
		end

		# TODO: this workflow assumes a backup previously exists.
		def back_up
			self.load_existing_tweet_backup
			self.download_tweets
			self.save
		end

		def load_existing_tweet_backup
			@tweets = self.load_and_format_tweets
			self.find_and_set_newest_tweet_id
			self.find_and_set_oldest_tweet_id
		end

		def find_and_set_newest_tweet_id
			@newest_tweet_id = self.find_newest_tweet_id
		end

		def find_newest_tweet_id
			return @tweets.keys.max{ |a,b| a <=> b }
		end

		def find_and_set_oldest_tweet_id
			@oldest_tweet_id = self.find_oldest_tweet_id
		end

		def find_oldest_tweet_id
			return @tweets.keys.min{ |a,b| a <=> b }
		end

		def download_tweets
			newest_tweet_id = self.get_newest_tweet.id
			cursor = @newest_tweet_id
			max_id = self.calculate_max_id(cursor)
			until @newest_tweet_id == newest_tweet_id do
				new_tweets = self.get_tweets(count: 200, since_id: cursor, max_id: max_id)
				formatted_tweets = self.format_all_api_tweets(new_tweets)
				self.merge_tweets(formatted_tweets)
				self.find_and_set_newest_tweet_id
				cursor = max_id
				max_id = self.calculate_max_id(cursor)
			end
		end

		def calculate_max_id(cursor)
			return cursor + TWEET_COUNT_INCREMENTER
		end

		def get_newest_tweet
			return self.get_tweets(count: 1, since_id: @newest_tweet_id).first
		end

		def get_tweets(**opts)
			begin
				tweets = @client.user_timeline(@screen_name, **opts, trim_user: true)
				return tweets
			rescue ::Twitter::Error::TooManyRequests => e
				rate_limit_length = e.rate_limit.reset_in
				rate_limit_length_in_minutes = rate_limit_length / 60

				puts %Q(
I'm being rate-limited by Twitter! Going to sleep for
#{rate_limit_length_in_minutes} minutes and then trying to fetch more tweets.
To speed this up, you might want to fetch your Twitter
archive from Twitter itself. Instructions are here:
https://help.twitter.com/en/managing-your-account/accessing-your-twitter-data
				)

				sleep rate_limit_length + 1
				retry
			end
		end

		# Load tweets and then replace all keys (Tweet ID) with integer values
		# of themselves. Need to do this because JSON doesn't allow integer
		# keys, so when we save the file as JSON they're automatically
		# converted to strings, which is useless for comparison when they're
		# reloaded.
		def load_and_format_tweets
			tweets = self.load_tweets
			tweets.map { |k,v| [k.to_i, v] }.to_h
		end

		def load_tweets
			return JSON.load(IO.read(@backup_file))
		end

		def save
			File.open(@backup_file, 'w') { |f| f.write(JSON.pretty_generate(@tweets)) }
		end

		# Format a tweet hash from a Tweet object from the Twitter gem.
		def format_api_tweet(tweet)
			{
				id: tweet.id,
				created_at: tweet.created_at,
				text: tweet.full_text,
				retweet: tweet.retweet?,
				original_tweet: tweet.retweeted_status.id,
				original_user: tweet.retweeted_status.user.id,
				reply: tweet.reply?,
				reply_to: tweet.in_reply_to_status_id,
				media: self.build_media_array(tweet)
			}
		end

		def build_media_array(tweet)
			tweet.media.map do |medium|
				{
					type: MEDIA_TYPES[medium.class.to_s],
					id: medium.id,
					url: medium.media_url.to_s
				}
			end
		end

		# Format a tweet hash from a hash imported from the Twitter
		# archive action.
		def format_archive_tweet(tweet)
			{
				id: tweet['id'].to_i,
				created_at: self.convert_datetime(tweet),
				text: tweet['full_text'],
				retweet: self.retweet?(tweet),
				original_tweet: self.get_original_tweet_status_id(tweet),
				original_user: self.get_original_tweet_user_id(tweet),
				reply: self.reply?(tweet),
				reply_to: self.get_reply_to_status_id(tweet),
				media: self.format_archive_media_array(tweet)
			}
		end

		def convert_datetime(tweet)
			return DateTime.parse(tweet['created_at']).strftime("%F %T %z")
		end

		# This would be a hell of a lot easier if the Twitter JSON
		# archive actually matched their API docs, but for some
		# reason they've decided to ditch the spectacularly useful
		# `retweeted_status` field in the archive, so we're stuck
		# with some really ugly parsing to figure out retweet data.
		def retweet?(tweet)
			return tweet['full_text'].start_with?('RT @')
		end

		# This may or may not exist for a retweet in the archive, yay.
		# If it doesn't exist here it doesn't exist in the data at all
		# so nil is fine.
		def get_original_tweet_status_id(tweet)
			return nil if not self.retweet?(tweet)

			begin
				return tweet['entities']['media'].first['source_status_id'].to_i
			rescue NoMethodError # love me some poorly structured data
				return nil
			end
		end

		def get_original_tweet_user_id(tweet)
			return nil if not self.retweet?(tweet)

			source_user_screen_name = tweet['full_text'].match(/RT @(.*):/).captures.first

			original_tweet_user_id = tweet['entities']['user_mentions'].find { |user|
				user['screen_name'] == source_user_screen_name
			}['id']

			return original_tweet_user_id.to_i
		end

		def reply?(tweet)
			return tweet['in_reply_to_status_id'].nil? ? false : true
		end

		def get_reply_to_status_id(tweet)
			return self.reply?(tweet) ? tweet['in_reply_to_status_id'].to_i : nil
		end

		def format_archive_media_array(tweet)
			return [] if not tweet['entities']['media']

			tweet['entities']['media'].map do |media|
				{
					type: media['type'].to_sym,
					id: media['id'],
					url: media['media_url']
				}
			end
		end

	end
end
