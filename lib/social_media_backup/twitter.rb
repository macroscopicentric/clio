#!/usr/bin/env ruby
# frozen_string_literal: true

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
    }.freeze

    TWEET_COUNT_INCREMENTER = 100_000_000_000_000

    ARCHIVE_FILE_PREFIX = 'window.YTD.tweets.part0 = '

    attr_accessor :tweets

    # backup_file is the file we write to; we don't assume
    # someone is starting with an existing backup file OR
    # that they already have a Twitter archive downloaded
    # through the Twitter UI (which is also formatted differently).
    def initialize(config = nil, backup_filename = nil)
      @client = configure_client(config) if config
      @screen_name = config['screen_name'] if config
      @backup_filename = backup_filename
      # @tweets is a hash where each key is a tweet id and the value is
      # the full content of the tweet as a hash.
      @tweets = {}
      @newest_tweet_id = nil
      @oldest_tweet_id = nil
    end

    def configure_client(config)
      client = ::Twitter::REST::Client.new do |c|
        c.consumer_key = config['consumer_key']
        c.consumer_secret = config['consumer_secret']
        c.access_token = config['access_token']
        c.access_token_secret = config['access_token_secret']
      end

      # This isn't a very sophisticated protection but I'm unsure
      # if there's a way to check valid credentials using the Twitter
      # gem without just trying to fetch something, so here we're
      # going to make sure we at least don't have an empty string for
      # one of the above values.
      raise StandardError, 'Invalid Twitter client credentials' unless client.credentials?

      client
    end

    # Twitter's API only allows you to GET the most recent 3200 tweets,
    # so anything older than that needs to be downloaded manually from
    # Twitter through the GUI and then imported via this method.
    def import_and_merge_twitter_archive(file_path)
      imported_tweets = import_twitter_archive(file_path)
      formatted_tweets = format_all_imported_tweets(imported_tweets)
      merge_tweets(formatted_tweets)
    end

    # Import tweets from an archive downloaded from Twitter. See
    # https://help.twitter.com/en/managing-your-account/accessing-your-twitter-data
    # for more information on how to download your own archive.
    # The files are almost perfect JSON except for a weird JS prefix,
    # so let's remove that and then actually JSONify the tweets.
    def import_twitter_archive(file_path)
      raise StandardError, 'Twitter archive file path was given but does not exist' unless File.exist?(file_path)

      # This gives you an array of hashes, where each hash has only
      # one key ("tweet") with a corresponding value. Get rid of the
      # extraneous key.
      JSON.parse(File.read(file_path).delete_prefix(ARCHIVE_FILE_PREFIX)).map { |tweet| tweet['tweet'] }
    end

    # Bulk format tweets downloaded via Twitter's archive action.
    def format_all_imported_tweets(imported_tweets)
      imported_tweets.map { |tweet| format_archive_tweet(tweet) }
    end

    # Bulk format tweets downloaded via the Twitter API gem.
    def format_all_api_tweets(downloaded_tweets)
      downloaded_tweets.map { |tweet| format_api_tweet(tweet) }
    end

    # Expects an array of hashes.
    def merge_tweets(imported_tweets)
      imported_tweets.each do |imported_tweet|
        id = imported_tweet[:id]
        @tweets[id] = imported_tweet unless tweet_in_tweets?(id)
      end
    end

    def tweet_in_tweets?(tweet_id)
      @tweets.key?(tweet_id)
    end

    # TODO: this workflow assumes a backup previously exists.
    def back_up
      load_existing_tweet_backup
      download_tweets
      save
    end

    def load_existing_tweet_backup
      @tweets = load_and_format_tweets
      find_and_set_newest_tweet_id
      find_and_set_oldest_tweet_id
    end

    def find_and_set_newest_tweet_id
      @newest_tweet_id = find_newest_tweet_id
    end

    def find_newest_tweet_id
      @tweets.keys.max { |a, b| a <=> b }
    end

    def find_and_set_oldest_tweet_id
      @oldest_tweet_id = find_oldest_tweet_id
    end

    def find_oldest_tweet_id
      @tweets.keys.min { |a, b| a <=> b }
    end

    def download_tweets
      newest_tweet_id = get_newest_tweet.id
      cursor = @newest_tweet_id
      max_id = calculate_max_id(cursor)
      until @newest_tweet_id == newest_tweet_id
        new_tweets = get_tweets(count: 200, since_id: cursor, max_id:)
        formatted_tweets = format_all_api_tweets(new_tweets)
        merge_tweets(formatted_tweets)
        find_and_set_newest_tweet_id
        cursor = max_id
        max_id = calculate_max_id(cursor)
      end
    end

    def calculate_max_id(cursor)
      cursor + TWEET_COUNT_INCREMENTER
    end

    # rubocop:disable Naming/AccessorMethodName
    # leave me alone, rubocop, this isn't an attr getter
    # https://stackoverflow.com/questions/26097084/why-does-rubocop-or-the-ruby-style-guide-prefer-not-to-use-get-or-set
    def get_newest_tweet
      get_tweets(count: 1, since_id: @newest_tweet_id).first
    end
    # rubocop:enable Naming/AccessorMethodName

    def get_tweets(**opts)
      @client.user_timeline(@screen_name, **opts, trim_user: true)
    rescue ::Twitter::Error::TooManyRequests => e
      rate_limit_length = e.rate_limit.reset_in
      rate_limit_length_in_minutes = rate_limit_length / 60

      puts %(
I'm being rate-limited by Twitter! Going to sleep for
#{rate_limit_length_in_minutes} minutes and then trying to fetch more tweets.
To speed this up, you might want to fetch your Twitter
archive from Twitter itself. Instructions are here:
https://help.twitter.com/en/managing-your-account/accessing-your-twitter-data
				)

      sleep rate_limit_length + 1
      retry
    end

    # Load tweets and then replace all keys (Tweet ID) with integer values
    # of themselves. Need to do this because JSON doesn't allow integer
    # keys, so when we save the file as JSON they're automatically
    # converted to strings, which is useless for comparison when they're
    # reloaded.
    def load_and_format_tweets
      tweets = load_tweets
      tweets.transform_keys(&:to_i)
    end

    def load_tweets
      begin
        tweets_from_backup = JSON.parse(IO.read(@backup_file))
      # if the file doesn't exist, assume we don't yet have a
      # backup and make one
      rescue Errno::ENOENT
        puts "File #{@backup_file} doesn't exist, I'm making it now"
        File.new(@backup_file)
        retry
      end

      tweets_from_backup
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
        media: build_media_array(tweet)
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
    # archive action. See spec fixture for an example of how the
    # Twitter archive is formatted as of 3/9/23.
    def format_archive_tweet(tweet)
      {
        id: tweet['id'].to_i,
        created_at: convert_datetime(tweet),
        text: tweet['full_text'],
        retweet: retweet?(tweet),
        original_tweet: get_original_tweet_status_id(tweet),
        original_user: get_original_tweet_user_id(tweet),
        reply: reply?(tweet),
        reply_to: get_reply_to_status_id(tweet),
        media: format_archive_media_array(tweet)
      }
    end

    def convert_datetime(tweet)
      DateTime.parse(tweet['created_at']).strftime('%F %T %z')
    end

    # There is a field under "tweet" called "retweeted" but
    # it doesn't seem correlated with whether my tweet is
    # originally a retweet, so my best guess is that it's
    # whether _my_ copy of the tweet has ever been retweeted?
    # Regardless, we're left with some ugly parsing here as
    # a result.
    def retweet?(tweet)
      tweet['full_text'].start_with?('RT @')
    end

    # This may or may not exist for a retweet in the archive, yay.
    # If it doesn't exist here it doesn't exist in the data at all
    # so nil is fine.
    def get_original_tweet_status_id(tweet)
      return nil unless retweet?(tweet)

      begin
        tweet['entities']['media'].first['source_status_id'].to_i
      rescue NoMethodError # love me some poorly structured data
        nil
      end
    end

    def get_original_tweet_user_id(tweet)
      return nil unless retweet?(tweet)

      # By default this is greedy so if there's more than one
      # colon this can get messy. Just grab the first word
      # boundary, which should include alphanumeric characters
      # and underscores.
      source_user_screen_name = tweet['full_text'].match(/RT @(\w+):/).captures.first

      tweet['entities']['user_mentions'].find do |user|
        # Neither the [upper/lower]case on screen_name are consistent,
        # absolutely incredible. Either can legitimately include uppercase
        # letters but they may not match.
        user['screen_name'].downcase == source_user_screen_name.downcase
      end['id'].to_i
    end

    def reply?(tweet)
      tweet['in_reply_to_status_id'].nil? ? false : true
    end

    def get_reply_to_status_id(tweet)
      reply?(tweet) ? tweet['in_reply_to_status_id'].to_i : nil
    end

    def format_archive_media_array(tweet)
      return [] unless tweet['entities']['media']

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
