# frozen_string_literal: true

require_relative '../spec_helper'

describe 'SocialMediaBackup::Twitter' do
  let(:tweet_text) { 'Exciting stuff happened.' }

  let(:tweet) do
    {
      id: 1,
      created_at: '2017-06-18 00:00:00 +0000',
      text: tweet_text,
      retweet: false,
      original_tweet: nil,
      original_user: nil,
      reply: false,
      reply_to: nil,
      media: []
    }
  end

  context '#import_twitter_archive' do
    # is there a better way to do this
    # this file is based on actual Twitter archive data
    # as of 3/9/23
    let(:archive_fixture_filename) do
      'spec/fixtures/tweets.js'
    end

    it "raises an error if a Twitter archive is given but doesn't exist" do
      twitter_backup = SocialMediaBackup::Twitter.new
      expect { twitter_backup.import_twitter_archive('garbage string') }.to raise_error(StandardError)
    end

    # check valid Twitter archive JSON
    it 'loads the JSON from the Twitter archive file correctly' do
      twitter_backup = SocialMediaBackup::Twitter.new
      jsonified_tweets = twitter_backup.import_twitter_archive(archive_fixture_filename)

      expect(jsonified_tweets).to be_an(Array)
      expect(jsonified_tweets[0]).to be_a(Hash)
    end
  end

  context '#format_archive_tweets' do
    let(:archive_tweet) do
      {
        'id' => '1',
        'created_at' => 'Sun Jun 18 00:00:00 +0000 2017',
        'full_text' => tweet_text,
        'entities' => {}

      }
    end

    let(:archive_reply_tweet) do
      {
        'in_reply_to_status_id' => '1',
        'id' => '2',
        'created_at' => 'Sun Aug 04 13:51:00 +0000 2019',
        'full_text' => 'This is a reply tweet.',
        'entities' => {}
      }
    end

    let(:username) { 'username' }
    let(:username_id) { '317' }

    let(:archive_retweeted_tweet) do
      {
        'id' => '3',
        'created_at' => 'Sun Aug 04 22:51:00 +0000 2019',
        'full_text' => "RT @#{username}: This is a retweet.",
        'entities' => {
          'urls' => [],
          'user_mentions' => [
            {
              'name' => 'Username',
              'screen_name' => 'username',
              'id' => '317'
            },
            {
              'name' => 'Fake Username',
              'screen_name' => 'fake_username',
              'id' => '775'
            }
          ]
        }
      }
    end

    let(:archive_tweet_with_media) do
      {
        'id' => '4',
        'created_at' => 'Sun Aug 04 22:51:00 +0000 2019',
        'full_text' => 'This is a tweet with media.',
        'entities' => {
          'media' => [
            {
              'media_url' => 'example.com/image.png',
              'id' => '34',
              'type' => 'photo'
            }
          ]
        }
      }
    end

    it 'formats a basic tweet from the Twitter archive correctly' do
      twitter_backup = SocialMediaBackup::Twitter.new
      formatted_tweet = twitter_backup.format_archive_tweet(archive_tweet)

      expect(formatted_tweet).to eq(tweet)
    end

    it 'formats a reply tweet from the Twitter archive correctly' do
      twitter_backup = SocialMediaBackup::Twitter.new
      formatted_tweet = twitter_backup.format_archive_tweet(archive_reply_tweet)

      expect(formatted_tweet).to include(reply: true)
      expect(formatted_tweet[:reply_to]).to be_an(Integer)
    end

    it 'formats a retweet from the Twitter archive correctly' do
      twitter_backup = SocialMediaBackup::Twitter.new
      formatted_tweet = twitter_backup.format_archive_tweet(archive_retweeted_tweet)

      expect(formatted_tweet).to include(retweet: true)
      expect(formatted_tweet[:original_user]).to eq(username_id.to_i)
    end

    it 'formats a tweet with media from the Twitter archive correctly' do
      twitter_backup = SocialMediaBackup::Twitter.new
      formatted_tweet = twitter_backup.format_archive_tweet(archive_tweet_with_media)

      expect(formatted_tweet[:media]).to_not be_empty
    end
  end

  context '#merge_tweets' do
    let(:twitter_backup) do
      twitter_backup = SocialMediaBackup::Twitter.new
      twitter_backup.tweets = { tweet[:id] => tweet }
      return twitter_backup
    end

    it "doesn't override the existing tweet backup" do
      new_tweet = tweet.dup
      new_tweet[:created_at] = '2017-6-19'
      new_tweets = [new_tweet]

      expect { twitter_backup.merge_tweets(new_tweets) }.to_not(change { twitter_backup.tweets })
    end

    it 'adds new tweets' do
      new_tweet = tweet.dup
      new_tweet[:id] = '2'
      new_tweets = [new_tweet]

      expect { twitter_backup.merge_tweets(new_tweets) }.to change { twitter_backup.tweets.length }.by(1)
    end
  end
end
