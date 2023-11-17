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
bin/smb backup
```

### Config

SMB expects a config file in the config subdirectory that matches `example.yml` and is called `smb.yml`.

### Twitter Config

`archive_file_path`: optional. The path to a download via the Twitter UI, typically a single file within the archive called `tweets.js`. 

`backup_file_path`: optional. The path to a previous backup using Social Media Backup, currently configured to be called `tweets.json`.

## Development

After checking out the repo, run `bundle install` to install depdencies. Then, run `rake spec` to run the tests.

Because this is a pet project, and one I rarely work on, it's much more of an aspirational product than a real one. See TODO.md for a(n ordered) realistic list of things that I'd like to do, and WISHLIST.md for a much less realistic list of things I'd like this project to be.

Rubocop is installed but does not run automatically. The entire project has been autoformatted with Rubocop.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magpieohmy/social_media_backup. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

