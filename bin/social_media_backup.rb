#!/usr/bin/env ruby
lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# backup file is the one we write to
# twitter archive is optional but is the json-formatted archive
# downloaded from the Twitter UI
backup_file, twitter_archive = ARGV

# require 'social_media_backup'

# SocialMediaBackup.back_up

require 'social_media_backup/twitter'
require 'yaml'

config = YAML.load_file('config.yml')

twitter_backup = SocialMediaBackup::Twitter.new(config['twitter'], backup_file)
twitter_backup.import_and_merge_twitter_archive(twitter_archive)
# twitter_backup.save
# twitter_backup.back_up
# twitter_backup.save
