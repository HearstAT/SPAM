#!/usr/bin/env ruby
# frozen_string_literal: true

require 'httparty'
require 'thor'
require 'yaml'
require 'date'
require 'pp'

module SPAM
  module COMMANDS
    # Target Commands
    class Register < Thor
      def initialize(*args)
        super
      end
    end
  end
end
