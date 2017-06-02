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

      def s3_put
        # TODO: Find out how to sync org pems to S3 or maybe just mount a s3 bucket?
        File.open("#{@org_path}/#{options[:org]}_sp_config.yml", 'rb') do |file|
          @s3.put_object(bucket: options[:aws_bucket], key: "#{options[:org]}_sp_config.yml", body: file)
        end
      end

      def s3_get
        File.open("#{@org_path}/#{options[:org]}_sp_config.yml", 'wb') do |file|
          s3.get_object(bucket: options[:aws_bucket], key: "#{options[:org]}_sp_config.yml") do |chunk|
            file.write(chunk)
          end
        end
      end

      def s3_delete
        @s3.delete_object(bucket: options[:aws_bucket], key: "#{options[:org]}_sp_config.yml")
        @s3.delete_object(bucket: options[:aws_bucket], key: options[:org_pem]) if @org['swarm']['managed']
      end
    end
  end
end
