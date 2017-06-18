#!/usr/bin/env ruby
lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# require 'social_media_backup'

# SocialMediaBackup.back_up

require 'social_media_backup/twitter'
require 'yaml'

config = YAML.load_file('config.yml')

twitter_backup = SocialMediaBackup::Twitter.new(config, 'test.json')
twitter_backup.import_and_merge_twitter_archive('tweets.csv')
twitter_backup.save
