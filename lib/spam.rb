#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thor'
require 'spam/version'
require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-s3'

Dir["#{File.dirname(__FILE__)}/spam/commands/*.rb"].each { |item| load(item) }

module SPAM
  # Main class to include Thor and load sub commands
  class SPAMCLI < Thor
    class_option :verbose, type: :boolean, aliases: :vv

    def initialize(*args)
      super
    end

    desc 'chef', 'chef plugin interaction'
    subcommand 'chef', SPAM::COMMANDS::Chef

    desc 'version', 'Get the version of the SPAM Tool'
    def version
      puts "SPAM version: #{SPAM::VERSION}"
    end
  end
end
