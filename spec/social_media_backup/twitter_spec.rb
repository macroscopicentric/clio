require_relative '../spec_helper'

describe 'SocialMediaBackup::Twitter' do

	let(:tweet_text) { 'Exciting stuff happened.' }
	let(:created_at) { '2017-06-18' }
	let(:media_url) { 'example.com/some_address' }

	let(:tweet) do
		{
			id: 1,
			created_at: created_at,
			text: tweet_text,
			retweet: false,
			original_tweet: '',
			original_user: '',
			reply: false,
			reply_to: '',
			media: [
				{ type: :url, id: nil, url: media_url }
			],
		}
	end

	context '#format_csv_tweet' do

		# The expected format for a tweet from the Twitter archive.
		let(:csv_tweet) do
			CSV::Row.new(
				[
					'tweet_id',
					'in_reply_to_status_id',
					'in_reply_to_user_id',
					'timestamp',
					'source',
					'text',
					'retweeted_status_id',
					'retweeted_status_user_id',
					'retweeted_status_timestamp',
					'expanded_urls'
				],
				[
					'1',
					'',
					'',
					created_at,
					'example.com',
					tweet_text,
					'',
					'',
					'',
					"#{media_url},#{media_url}"
				]
			)
		end

		it "formats a csv tweet correctly" do
			twitter_backup = SocialMediaBackup::Twitter.new
			formatted_tweet = twitter_backup.format_csv_tweet(csv_tweet)

			expect(formatted_tweet[:media].length).to be(1)
			expect(formatted_tweet).to eq(tweet)
		end

	end

	context '#merge_tweets' do

		let(:twitter_backup) do
			twitter_backup = SocialMediaBackup::Twitter.new
			twitter_backup.tweets = {tweet[:id] => tweet}
			return twitter_backup
		end

		it "doesn't override the existing tweet backup" do
			new_tweet = tweet.dup
			new_tweet[:created_at] = '2017-6-19'
			new_tweets = [new_tweet]

			expect { twitter_backup.merge_tweets(new_tweets) }.to_not change { twitter_backup.tweets }
		end

		it 'adds new tweets' do
			new_tweet = tweet.dup
			new_tweet[:id] = '2'
			new_tweets = [new_tweet]

			expect { twitter_backup.merge_tweets(new_tweets) }.to change { twitter_backup.tweets.length }.by(1)
		end

	end
end