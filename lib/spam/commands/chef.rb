#!/usr/bin/env ruby
# frozen_string_literal: true

require 'httparty'
require 'thor'
require 'yaml'
require 'date'
require 'pp'

module SPAM
  module COMMANDS
    # Chef Commands
    class Chef < Thor
      def initialize(*args)
        super
      end

      class_option :org, aliases: :o, required: true, banner: 'CHEF_ORG - sets chef org'
      class_option :port, aliases: :p, required: true, banner: 'PORT - sets port for org smart proxy group'
      class_option :vpc, aliases: :vpc, required: true, banner: 'VPC_ID - sets VPC ID'
      class_option :listener_arn, aliases: :l, required: true, banner: 'ARN - sets the listener arn for registered targets'
      class_option :aws_region, aliases: :r, banner: 'REGION - Overrides any region currently set'
      class_option :protocol, aliases: :pr, banner: 'HTTP/HTTPS - Sets protocol for ALB Rule, default HTTP'
      class_option :priority, aliases: :p, required: true, banner: 'REGION - Overrides any region currently set'
      class_option :targets, aliases: :t, required: true, banner: 'i-dfaj93,i-fi9a3mio - Pass targets to register to ALB ground'
      class_option :foreman_user, aliases: :user, required: true, banner: 'USER - Username for Foreman to Create Smart Proxy'
      class_option :foreman_password, aliases: :password, required: true, banner: 'PASSWORD - Password for Foreman to Create Smart Proxy'
      class_option :proxy_url, aliases: :url, required: true, banner: 'http://url.com/org - Complete URL for Smart Proxy'
      class_option :location_ids, aliases: :locids, banner: 'LOCATION_IDS - If locations are enabled, provide location id(s) to assign smart proxy to'
      class_option :organization_ids, aliases: :orgids, banner: 'ORGANIZATION_IDS - If organizations are enabled, provide organization id(s) to assign smart proxy to'

      desc 'create', 'Creates org ALB for smart proxy'
      def create
        set_region
        client
        target = create_group
        create_rule(target['target_groups']['target_group_arn'])
        targets = []
        options[:targets].each do |t|
          targets.push "{id: #{t}}"
        end
        register(target['target_groups']['target_group_arn'], targets)
      end

      desc 'delete', 'Deletes org ALB for smart proxy'
      def delete
        set_region
        client
        @albclient
      end

      no_commands do
        def set_region
          @region = ENV['AWS_REGION'] if ENV['AWS_REGION']
          @region = Aws.config[:region] if Aws.config[:region]
          @region = options[:region] if options[:region]
        end

        def client
          @albclient = Aws::ElasticLoadBalancingV2::Client.new(region: @region)
        rescue Aws::Errors::MissingRegionError
          puts '[WARNING] - Region not set! Please set a region via environment variable AWS_REGION, aws config, or --region=REGION'
        end

        def create_group
          @albclient.create_target_group(
            name: options[:name] ? options[:name] : "#{options[:org]}-foreman-chef-proxy",
            port: options[:port],
            protocol: options[:protocol] ? options[:protocol] : 'HTTP',
            vpc_id: options[:vpc]
          ).to_h
        end

        def create_rule(target)
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

        def register_targets(arn, targets)
          @albclient.register_targets(
            target_group_arn: arn,
            targets: targets
          )
        end

        def create_sp
          auth = {
            username: options[:foreman_user],
            password: options[:foreman_password]
          }

          body = {
            name: options[:name] ? options[:name] : "#{options[:org]}-chef-proxy",
            url: options[:proxy_url]
          }

          body[:location_ids] = options[:location_ids].to_a if options[:location_ids]
          body[:organization_ids] = options[:organization_ids].to_a if options[:organization_ids]
          HTTParty.post(
            "#{options[:foreman_url]}/api/smart_proxies",
            body: body,
            basic_auth: auth
          )
        end
      end
    end
  end
end
