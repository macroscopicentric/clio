#!/usr/bin/env ruby
require 'yaml'

class SocialMediaBackup
  require 'social_media_backup/twitter'

  SOCIAL_MEDIA_PLATFORMS = [Twitter]

  def initialize(config_path)
    @config = load_config(config_path)
  end

  def self.back_up
    SOCIAL_MEDIA_PLATFORMS.each { |platform| platform.back_up }
  end

  def load_config(config_path)
    YAML.load_file(config_path)
  end
end
