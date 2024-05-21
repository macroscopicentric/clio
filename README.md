# Clio - A Social Media Backup

The vision:
A service to back up different social media types and bundle them into a directory of files on disk that can then be compressed down into a single file for portability. Clio should be able to be run as a local web app or on a local server like a NAS (open question: scheduling?), and long-term may be hosted as more of a SAAS type product on the internet somewhere.

### Supported Social Medias

* ~~Twitter~~
* Tumblr

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'clio'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install clio

## Usage

Use the bin file as the entrypoint, ex:

```shell
bin/smb backup
```

### Config

Clio expects a config file in the config subdirectory that matches `example.yml` and is called `smb.yml`.

### Twitter

As of Twitter's API V2, there is no free tier with read capabilities for accessing Twitter via the API anymore. So while there is a new gem ([x-ruby](https://sferik.github.io/x-ruby/)) to support accessing V2, I have simply deleted that backup engine. You may request an archive of your own Twitter data [from your Twitter settings here](https://twitter.com/settings/download_your_data) instead.

## Development

After checking out the repo, run `bundle install` to install depdencies. Then, run `rake spec` to run the tests.

To install git hooks (currently just a pre-commit hook that runs Rubocop for linting), do
```sh
$ ./scripts/install-hooks.sh
```

Because this is a pet project, and one I rarely work on, it's much more of an aspirational product than a real one. See TODO.md for a(n ordered) list of next steps.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magpieohmy/clio. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

