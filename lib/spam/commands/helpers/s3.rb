# frozen_string_literal: true

module SPAM
  module COMMANDS
    # Extends Chef Class
    class Chef
      private

      def s3
        Aws::S3::Client.new(region: @region)
      rescue Aws::Errors::MissingRegionError
        raise '[WARNING] - Region not set! Please set a region via environment variable AWS_REGION, aws config, SPAM config, or --region=REGION'
      end

      def s3_sync
      end

      def s3_delete
      end
    end
  end
end
