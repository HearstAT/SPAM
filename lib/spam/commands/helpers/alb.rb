# frozen_string_literal: true

module SPAM
  module COMMANDS
    # Extends Chef Class
    class Chef
      private

      def alb
        Aws::ElasticLoadBalancingV2::Client.new(region: @region)
      rescue Aws::Errors::MissingRegionError
        raise '[WARNING] - Region not set! Please set a region via environment variable AWS_REGION, aws config, SPAM config, or --region=REGION'
      end

      def alb_create_group
        @albclient.create_target_group(
          name: options[:group_name] ? options[:group_name] : "#{options[:org]}-foreman-chef-proxy",
          port: options[:port],
          protocol: options[:protocol] ? options[:protocol] : 'HTTP',
          vpc_id: options[:vpc]
        ).to_h
      end

      def alb_create_rule(target)
        @albclient.create_rule(
          actions: [
            {
              target_group_arn: target,
              type: 'forward'
            }
          ],
          conditions: [
            {
              field: 'path-pattern',
              values: [
                "/#{options[:org]}*"
              ]
            }
          ],
          listener_arn: options[:listener_arn],
          priority: options[:priority]
        ).to_h
      end

      def alb_register(arn, targets)
        @albclient.register_targets(
          target_group_arn: arn,
          targets: targets
        )
      end

      def alb_delete_group
      end

      def alb_delete_rule
      end
    end
  end
end
