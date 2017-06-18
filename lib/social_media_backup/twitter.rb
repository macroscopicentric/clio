# things to save from a tweet (client.user_timeline('username')):
# id "Using a signed 64 bit integer for storing this identifier is safe." (or stringify?)
# created_at
# dm or tweet
# text (full_text from dms) if text?
# original_tweet.id & original_tweet.user.screen_name if retweet?
# reply?
# media if media?

require 'json'
require 'csv'
require 'twitter'

class SocialMediaBackup
	class Twitter

		MEDIA_TYPES = {
			'Twitter::Media::AnimatedGif' => :animated_gif,
			'Twitter::Media::Photo' => :photo,
			'Twitter::Media::Video' => :video
		}

		attr_reader :tweets

		def initialize(backup_file:, config:)
			@backup_file = backup_file
			@client = configure_client(config)
			@screen_name = config['screen_name']
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
		def import_and_merge_twitter_archive(file_path)
			imported_tweets = self.import_twitter_archive(file_path)
			formatted_tweets = self.format_all_imported_tweets(imported_tweets)
			self.merge_tweets(formatted_tweets)
		end

		def import_twitter_archive(file_path)
			imported_tweets = CSV.read(file_path, headers: true)
			return imported_tweets
		end

		def format_all_imported_tweets(imported_tweets)
			return imported_tweets.map {|tweet| self.format_csv_tweet(tweet)}
		end

		def merge_tweets(imported_tweets)
			imported_tweets.each do |imported_tweet|
				puts imported_tweet
				id = imported_tweet[:id]
				@tweets[id] = imported_tweet unless self.tweet_in_tweets?(id)
			end
		end

		def tweet_in_tweets?(tweet_id)
			return @tweets.key?(tweet_id)
		end

		def back_up
			existing_tweet_backup = self.load_existing_tweet_backup
			self.download_tweets
			self.merge_tweets(existing_tweet_backup)
			self.save_tweets_to_json
		end

		def load_existing_tweet_backup
			existing_tweet_backup = self.load_tweets_from_json
			@newest_tweet_id = self.find_newest_tweet_id(existing_tweet_backup)
			@oldest_tweet_id = self.find_oldest_tweet_id(existing_tweet_backup)
			return existing_tweet_backup
		end

		def find_newest_tweet_id(tweets)
			id = tweets.max{|a,b| a[:id] <=> b[:id]}
		end

		def find_oldest_tweet_id(tweets)
			id = tweets.max{|a,b| a[:id] <=> b[:id]}
		end

		def download_tweets
			self.download_old_tweets
			self.download_new_tweets
		end

		# def download_old_tweets
		# 	current_oldest_tweet_id = find_oldest_tweet_id(@tweets)
		# 	while current_oldest_tweet_id != @oldest_tweet_id (&) @tweets.length > 3200
		# 		max_id = current_oldest_tweet_id - 1
		# 		new_tweets = @client.user_timeline(@screen_name, count: 200, max_id: max_id).map do |tweet|
		# 			self.format_tweet_object(tweet)
		# 		end
		# 		current_oldest_tweet_id = find_oldest_tweet_id(new_tweets)
		# 		@tweets.replace(@tweets + new_tweets)
		# 	end
		# end

		# def download_new_tweets
		# 	current_newest_tweet_id = find_newest_tweet_id(@tweets)
		# 	while current_newest_tweet_id != @newest_tweet_id (&) @tweets.length > 3200
		# 		since_id = current_newest_tweet_id
		# 		new_tweets = @client.user_timeline(@screen_name, count: 200, since_id: since_id).map do |tweet|
		# 			self.format_tweet_object(tweet)
		# 		end
		# 		current_newest_tweet_id = find_newest_tweet_id(new_tweets)
		# 		@tweets.replace(new_tweets + @tweets)
		# 	end
		# end

		def load_tweets_from_json
			return JSON.load(File.open(@backup_file, 'w'))
		end

		def format_and_save_tweets(tweets)
			formatted_tweets = self.format_tweets_to_json(tweets)
			self.save_tweets_to_json(formatted_tweets)
		end

		def save
			File.open(@backup_file, 'w') {|f| f.write(JSON.pretty_generate(@tweets))}
		end

		def build_media_hash(tweet)
			tweet.media.map do |media|
				{
					type: MEDIA_TYPES[media.class.to_s],
					id: media.id,
					url: media.media_url.to_s
				}
			end
		end

		# Format a tweet hash from a hash imported from the Twitter CSV
		# archiving button.
		def format_csv_tweet(tweet)
			{
				id: tweet['tweet_id'],
				created_at: tweet['timestamp'],
				text: tweet['text'],
				retweet: tweet['retweeted_status_id'].empty? ? false : true,
				original_tweet: tweet['retweeted_status_id'],
				original_user: tweet['retweeted_status_user_id'],
				reply: tweet['in_reply_to_status_id'].empty? ? false : true,
				reply_to: tweet['in_reply_to_status_id'],
				media: self.format_csv_media_hash(tweet)
			}
		end

		def format_csv_media_hash(tweet)
			#Need to turn into a set first because there are a lot of repeat expanded_urls for some reason.
			tweet['expanded_urls'].split(',').uniq.map do |url|
				{
					type: :url,
					id: nil,
					url: url
				}
			end
		end

	end
end
