# frozen_string_literal: true

require 'thor'
require 'spam/version'
require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-s3'
require 'yaml'

Dir["#{File.dirname(__FILE__)}/spam/commands/**/*.rb"].each { |item| load(item) }

module SPAM
  # Main class to include Thor and load sub commands
  class SPAMCLI < Thor
    class_option :verbose, type: :boolean, desc: 'Run with verbose output'

    def initialize(*args)
      super
      options
    end

    desc 'chef', 'Chef plugin interaction'
    subcommand 'chef', SPAM::COMMANDS::Chef

    desc 'version', 'Get the version of the SPAM Tool'
    def version
      puts "SPAM version: #{SPAM::VERSION}"
    end

    private

    def options
      @config_file = '~/.spam/config.yml'
      original_options = super
      return original_options unless File.exist?(@config_file)
      defaults = File.size?(@config_file).nil? ? {} : YAML.load_file(@config_file) if File.exist?(@config_file)
      Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options)) if File.exist?(@config_file)
    end
  end
end
