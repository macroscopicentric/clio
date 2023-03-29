# Social Media Backup

A service to back up different social media types to a Postgres database. This is EXTREMELY work-in-progress, do not expect literally anything to work properly.

###Supported Social Medias

* Twitter

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'social_media_backup'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install social_media_backup

## Usage

Use the bin file as the entrypoint, ex:

```shell
bin/social_media_backup.rb [twitter backup] [twitter archive]
```

Where "twitter backup" is a JSON file of a previous backup via this gem, and "twitter archive" is a tweets.js file downloaded as part of your Twitter archive (fetched manually via the Twitter UI).

## Development

After checking out the repo, run `bundle install` to install depdencies. Then, run `rake spec` to run the tests.

Because this is a pet project, and one I rarely work on, it's much more of an aspirational product than a real one. See TODO.md for a(n ordered) realistic list of things that I'd like to do, and WISHLIST.md for a much less realistic list of things I'd like this project to be.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magpieohmy/social_media_backup. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

