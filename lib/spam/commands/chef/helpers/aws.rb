# frozen_string_literal: true

module SPAM
  module COMMANDS
    # Extends Chef Class
    class Chef
      private

      def set_region
        @region = ENV['AWS_REGION'] if ENV['AWS_REGION']
        @region = Aws.config[:region] if Aws.config[:region]
        @region = options[:region] if options[:region]
      end
    end
  end
end
