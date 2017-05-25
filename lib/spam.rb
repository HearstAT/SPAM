#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thor'
require 'spam/version'

Dir["#{File.dirname(__FILE__)}/spam/commands/*.rb"].each { |item| load(item) }

module SPAM
  # Main class to include Thor and load sub commands
  class SPAMCLI < Thor
    def initialize(*args)
      super
      @region = ENV['AWS_REGION'] ? ENV['AWS_REGION'] : args[0]
      @albclient = Aws::ElasticLoadBalancingV2::Client.new(region: @region)
    end

    desc 'target', 'target group'
    subcommand 'target', SPAM::COMMANDS::Target

    desc 'rule', 'listener rules'
    subcommand 'rule', SPAM::COMMANDS::Rule

    desc 'register', 'register targets'
    subcommand 'register', SPAM::COMMANDS::Register

    desc 'version', 'Get the version of the SPAM Tool'
    def version
      puts "SPAM version: #{SPAM::VERSION}"
    end
  end
end
