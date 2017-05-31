# frozen_string_literal: true

require 'fileutils'
require 'httparty'
require 'thor'
require 'pp'
require 'docker'
require 'docker-swarm-api'
require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-s3'
require 'yaml'

module SPAM
  module COMMANDS
    # Chef Commands
    class Chef < Thor
      require_relative 'helpers/docker'
      require_relative 'helpers/alb'
      require_relative 'helpers/foreman'
      def initialize(*args)
        super
      end

      ## Required, either flag or set in ~/.spam/config.yml
      class_option :org,              type: :string,  required: true, desc: 'CHEF_ORG - sets chef org'
      class_option :port,             type: :numeric, required: true, desc: 'PORT - sets port for org smart proxy group'
      class_option :vpc,              type: :string,  required: true, desc: 'VPC_ID - sets VPC ID'
      class_option :listener_arn,     type: :string,  required: true, desc: 'ARN - sets the listener arn for registered targets'
      class_option :priority,         type: :numeric, required: true, desc: 'NUM - Sets ALB Rule Priority'
      class_option :targets,          type: :string,  required: true, desc: 'INSTANCE_ID(S) - Pass target(s) to register in ALB Target Group'
      class_option :foreman_user,     type: :string,  required: true, desc: 'USER - Username for Foreman to Create Smart Proxy'
      class_option :foreman_password, type: :string,  required: true, desc: 'PASSWORD - Password for Foreman to Create Smart Proxy'
      class_option :proxy_url,        type: :string,  required: true, desc: 'URL - Base URL for Smart Proxy http://proxy.domain.com/'

      ## Optional
      class_option :verbose,          type: :boolean
      class_option :swarm_init,       type: :boolean, desc: 'BOOLEAN - Create Swarm, only use on leader (Default: --no-swarm-init)'
      class_option :swarm_ip,         type: :string,  desc: 'IP - Swarm Manager/Leader IP'
      class_option :swarm_name,       type: :string,  desc: 'NAME - Name of the Swarm Service (Default: org-chef-proxy)'
      class_option :swarm_join,       type: :boolean, desc: 'BOOLEAN - Add Current Instance to Swarm (Default --no-swarm-join)'
      class_option :swarm_as,         type: :string,  desc: 'TYPE - Join swarm as Manager or Worker'
      class_option :swarm_image,      type: :string,  desc: 'DOCKER IMAGE - Image to create smart proxies with (Default: hearstat/chef-smart-proxy)'
      class_option :org_client,       type: :string,  desc: 'NAME - Org Client name that has Right on Chef Server'
      class_option :org_path,         type: :string,  desc: 'PATH - Path to create org files and load pems from'
      class_option :pem_path,         type: :string,  desc: 'PATH - Path to load pem files from (Default: Org Path)'
      class_option :org_pem,          type: :string,  desc: 'PEM - PEM File that belongs to client'
      class_option :chef_url,         type: :string,  desc: 'URL - Complete URL to Chef Server https://chef.domain.com'
      class_option :group_name,       type: :string,  desc: 'NAME - Name of ALB Target Group (Default: org-foreman-chef-proxy)'
      class_option :proxy_name,       type: :string,  desc: 'NAME - Name of Smart Proxy in Foreman (Default: org-chef-proxy)'
      class_option :aws_region,       type: :string,  desc: 'REGION - Overrides any region currently set'
      class_option :aws_bucket,       type: :string,  desc: 'BUCKET_NAME - Enter bucket to sync data to'
      class_option :protocol,         type: :string,  desc: 'HTTP/HTTPS - Sets protocol for ALB Rule, default HTTP'
      class_option :location_ids,     type: :string,  desc: 'LOCATION_IDS - Foreman Location ID(s) to assign smart proxy to'
      class_option :organization_ids, type: :string,  desc: 'ORGANIZATION_IDS - Foreman Organization ID(s) to assign smart proxy to'

      desc 'create', 'Creates org ALB for smart proxy'
      def create
        init
        target = alb_create_group
        alb_create_rule(target['target_groups']['target_group_arn'])
        targets = options[:targets].split(',')
        alb_register(target['target_groups']['target_group_arn'], targets)
        swarm_init if options[:swarm_init]
        swarm_join if options[:swarm_join]
        File.open("#{@org_path}/#{options[:org]}_sp_config.yml", 'w') do |file|
          file.write target['target_groups']['target_group_arn'].to_yaml
        end
        s3_put if options[:aws_bucket]
      end

      desc 'delete', 'Deletes org ALB for smart proxy'
      def delete
        init
        s3_get if options[:aws_bucket]
        load_org
      end

      desc 'add', 'Add EC2 to ALB Target (Optional: Docker Swarm Join)'
      def add
        init
        s3_get if options[:aws_bucket]
        load_org
      end

      desc 'list', 'List managed orgs and Details'
      def list
        init
        s3_get if options[:aws_bucket]
        load_org
      end

      private

      def init
        set_region
        @org_path = options[:org_path] ? options[:org_path] : '~/.spam/orgs'
        FileUtils.mkdir_p @org_path
        @alb = alb
        @s3 = s3
      end

      def load_org
        # Load org yaml file into hash
      end
    end
  end
end
