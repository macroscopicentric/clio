require_relative '../spec_helper'

describe 'SocialMediaBackup::Twitter' do
	let(:tweet) do
		{
			id: '1',
			created_at: '2017-6-18',
			text: 'Exciting stuff happened.',
			retweet: false,
			original_tweet: '',
			original_user: '',
			reply: false,
			reply_to: '',
			media: []
		}
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