require 'yaml'

module Clio
    class Archive
      def initialize(config_path)
        @config = load_config(config_path)
      end

      def load_config(config_path)
        YAML.load_file(config_path)
      end

      def save_config(config_path)
      end

      def self.back_up()
      end
    end
end