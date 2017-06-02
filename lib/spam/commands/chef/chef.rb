# frozen_string_literal: true

require 'fileutils'
require 'httparty'
require 'thor'
require 'docker'
require 'docker-swarm-api'
require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-s3'
require 'yaml'
require 'socket'

module SPAM
  module COMMANDS
    # Chef Commands
    class Chef < Thor
      require_relative 'helpers/docker'
      require_relative 'helpers/alb'
      require_relative 'helpers/foreman'
      require_relative 'helpers/s3'
      def initialize(*args)
        super
      end

      ## Optional
      class_option :verbose,          type: :boolean, desc: 'Run with verbose output'
      class_option :aws_region,       type: :string,  desc: 'REGION - Overrides any region currently set'
      class_option :aws_bucket,       type: :string,  desc: 'BUCKET_NAME - Enter bucket to sync data to'

      desc 'create', 'Creates org ALB for smart proxy'
      ## Required, either flag or set in ~/.spam/config.yml
      option :org,              type: :string,  required: true, desc: 'CHEF_ORG - sets chef org'
      option :port,             type: :numeric, required: true, desc: 'PORT - sets port for org smart proxy group'
      option :vpc,              type: :string,  required: true, desc: 'VPC_ID - sets VPC ID'
      option :listener_arn,     type: :string,  required: true, desc: 'ARN - sets the listener arn for registered targets'
      option :priority,         type: :numeric, required: true, desc: 'NUM - Sets ALB Rule Priority'
      option :targets,          type: :string,  required: true, desc: 'INSTANCE_ID(S) - Pass target(s) to register in ALB Target Group'
      option :foreman_user,     type: :string,  required: true, desc: 'USER - Username for Foreman to Create Smart Proxy'
      option :foreman_password, type: :string,  required: true, desc: 'PASSWORD - Password for Foreman to Create Smart Proxy'
      option :proxy_url,        type: :string,  required: true, desc: 'URL - Base URL for Smart Proxy http://proxy.domain.com/'
      # Optional
      option :protocol,         type: :string,  desc: 'HTTP/HTTPS - Sets protocol for ALB Rule, default HTTP'
      option :location_ids,     type: :string,  desc: 'LOCATION_IDS - Foreman Location ID(s) to assign smart proxy to'
      option :organization_ids, type: :string,  desc: 'ORGANIZATION_IDS - Foreman Organization ID(s) to assign smart proxy to'
      option :group_name,       type: :string,  desc: 'NAME - Name of ALB Target Group (Default: org-foreman-chef-proxy)'
      option :proxy_name,       type: :string,  desc: 'NAME - Name of Smart Proxy in Foreman (Default: org-chef-proxy)'
      option :swarm_init,       type: :boolean, desc: 'BOOLEAN - Create Swarm, only use on leader (Default: --no-swarm-init)'
      option :swarm_public,     type: :boolean, desc: 'BOOLEAN - Make swarm leader listen on public address? (Default: --no-swarm-public)'
      option :swarm_name,       type: :string,  desc: 'NAME - Name of the Swarm Service (Default: org-chef-proxy)'
      option :swarm_image,      type: :string,  desc: 'DOCKER IMAGE - Image to create smart proxies with (Default: hearstat/chef-smart-proxy)'
      option :swarm_ip,         type: :string,  desc: 'IP - Swarm Manager/Leader IP'
      option :node_public,      type: :boolean, desc: 'BOOLEAN - Node Advertise IP for Swarm (Default: --no-node-public, aka local IPv4)'
      option :swarm_scale,      type: :numeric, desc: 'NUM - Set number of proxies (containers) to run in swarm'
      option :org_client,       type: :string,  desc: 'NAME - Org Client name that has rights on Chef Server'
      option :org_path,         type: :string,  desc: 'PATH - Path to create org files and load pems from'
      option :pem_path,         type: :string,  desc: 'PATH - Path to load pem files from (Default: Org Path)'
      option :org_pem,          type: :string,  desc: 'PEM - PEM File that belongs to client'
      option :chef_url,         type: :string,  desc: 'URL - Complete URL to Chef Server https://chef.domain.com'

      def create
        init
        @albgroup = alb_create_group
        alb_create_rule(@albgroup['target_groups']['target_group_arn'])
        targets = options[:targets].split(',')
        alb_register(@albgroup['target_groups']['target_group_arn'], targets)
        swarm_opts if options[:swarm_init]
        swarm_init if options[:swarm_init]
        write_org
        # validate_org # TODO: Create validation for create command
        s3_put if options[:aws_bucket]
      end

      desc 'delete', 'Deletes org ALB for smart proxy'
      ## Required, either flag or set in ~/.spam/config.yml
      option :org, type: :string, required: true, desc: 'CHEF_ORG - sets chef org'
      def delete
        init
        s3_get if options[:aws_bucket]
        load_org
        swarm_opts if @org['swarm']['managed']
        # delete_alb # TODO: Create delete alb
        # delete swarm if @org['swarm']['managed'] # TODO: create delete swarm
        # delete_foreman # TODO: Create delete foreman smart proxy
        # delete_s3 if options[:aws_bucket] # # TODO: create delete S3, Use different option?
      end

      desc 'add', 'Add EC2 to ALB Target (Optional: Docker Swarm Join)'
      ## Required, either flag or set in ~/.spam/config.yml
      option :org,           type: :string,  required: true, desc: 'CHEF_ORG - sets chef org'
      option :targets,       type: :string,  required: true, desc: 'INSTANCE_ID(S) - Pass target(s) to register in ALB Target Group'
      # Optional
      option :swarm_join,    type: :boolean, desc: 'BOOLEAN - Add Current Instance to Swarm (Default: --no-swarm-join)'
      option :swarm_manager, type: :boolean, desc: 'BOOLEAN - Join swarm as Manager (Default: --no-swarm-manager, aka join as worker)'
      option :swarm_ip,      type: :string,  desc: 'IP - Swarm Manager/Leader IP'
      option :node_public,   type: :boolean, desc: 'BOOLEAN - Node Advertise IP for Swarm (Default: --no-node-public, aka local IPv4)'
      option :swarm_scale,   type: :numeric, desc: 'NUM - Set number of proxies (containers) to run in swarm'
      option :org_path,      type: :string,  desc: 'PATH - Path to create org files and load pems from'

      def add
        init
        s3_get if options[:aws_bucket]
        load_org
        swarm_opts if options[:swarm_join]
        swarm_join if options[:swarm_join]
        alb_register(@org_config['alb']['target_group_arn'], targets)
        # validate_org # TODO: Create add validation
      end

      desc 'list', 'List managed orgs and Details'
      ## Required, either flag or set in ~/.spam/config.yml
      option :org, type: :string, required: true, desc: 'CHEF_ORG - sets chef org'
      def list
        init
        s3_get if options[:aws_bucket]
        load_org
        # list_orgs # TODO: Create readable output of managed org and possibly status
      end

      private

      def init
        set_region
        @org_path = options[:org_path] ? options[:org_path] : '~/.spam/orgs'
        FileUtils.mkdir_p @org_path
        @alb = alb
        @s3 = s3 if options[:aws_bucket]
      end

      def swarm_opts
        @image = options[:swarm_image] ? options[:swarm_image] : 'hearstat/chef-smart-proxy'
        @scale = options[:swarm_scale] ? options[:swarm_scale] : '1'
        @swarm_ip = swarm_ip
        @node_ip = node_ip
        @join_token = join_token unless options[:swarm_init]
      end

      def write_org
        org_file = YAML.load_file("#{@org_path}/#{options[:org]}_sp_config.yml")
        org_file['alb']['target_group_arn'] = @albgroup['target_groups']['target_group_arn']
        org_file['swarm']['managed'] = options[:swarm_init] ? true : false
        org_file['swarm']['ip'] = @swarm_ip if options[:swarm_init]
        org_file['swarm']['manager_token'] = @swarm.manager_join_token if options[:swarm_init]
        org_file['swarm']['worker_token'] = @swarm.worker_join_token if options[:swarm_init]
        File.open("#{@org_path}/#{options[:org]}_sp_config.yml", 'w') { |f| f.write org_file.to_yaml }
      end

      def load_org
        @org_config = YAML.load_file("#{@org_path}/#{options[:org]}_sp_config.yml")
      end
    end
  end
end
