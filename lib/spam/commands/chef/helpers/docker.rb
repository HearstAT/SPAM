# frozen_string_literal: true

module SPAM
  module COMMANDS
    # Extends Chef Class
    class Chef
      private

      def swarm_ip
        if options[:swarm_init]
          Socket.ip_address_list.detect(&:ipv4_public?).ip_address if options[:swarm_public]
          Socket.ip_address_list.detect(&:ipv4_private?).ip_address unless options[:swarm_public]
        else
          options[:swarm_ip] ? options[:swarm_ip] : @org_config['swarm_ip']
        end
      end

      def node_ip
        Socket.ip_address_list.detect(&:ipv4_public?).ip_address if options[:node_public]
        Socket.ip_address_list.detect(&:ipv4_private?).ip_address unless options[:node_public]
      end

      def create_swarm
        leader_connection = Docker::Swarm::Connection.new('unix:///var/run/docker.sock')
        swarm_init_options = { 'ListenAddr' => "#{swarm_ip}:2377" } unless options[:swarm_public]
        swarm_init_options = { 'ListenAddr' => '0.0.0.0:2377' } if options[:swarm_public]
        @swarm = Docker::Swarm::Swarm.init(swarm_init_options, leader_connection)
        swarm_name = options[:swarm_name] ? options[:swarm_name] : 'org-chef-proxy'
        create_service(swarm_name)
      end

      def create_service(name)
        service_create_options = {
          'Name' => name,
          'TaskTemplate' => {
            'ContainerSpec' => {
              'Image' => @image,
              'Mounts' => [] # TODO: Find out how to bind mounts
            },
            'Env' => [
              "FOREMAN_URL=#{options[:foreman_url]}",
              "CHEF_URL=#{options[:chef_url]}",
              "CHEF_ORG=#{options[:org]}",
              "ORG_CLIENT=#{options[:org_client]}"
            ],
            'LogDriver' => {
              'Name' => 'json-file',
              'Options' => { 'max-file' => '3', 'max-size' => '10M' }
            },
            'RestartPolicy' => {
              'Condition' => 'on-failure',
              'Delay' => 1,
              'MaxAttempts' => 3
            }
          },
          'Mode' => {
            'Replicated' => { 'Replicas' => @scale }
          },
          'UpdateConfig' => {
            'Delay' => 2,
            'Parallelism' => 2,
            'FailureAction' => 'pause'
          },
          'EndpointSpec' => {
            'Ports' => [{
              'Protocol' => 'tcp',
              'PublishedPort' => 8080,
              'TargetPort' => options[:port]
            }]
          }
        }
        @swarm_service = swarm.create_service(service_create_options)
      end

      def add_to_swarm
        swarm_options = {
          'manager_ip' => @swarm_ip,
          'node_ip' => @node_ip,
          'JoinTokens' => {
            'Master' => @org_config['swarm']['manager_token'],
            'Worker' => @org_config['swarm']['worker_token']
          }
        }
        @swarm = Docker::Swarm::Swarm.new(swarm_options)
        local_connection = Docker::Swarm::Connection.new('unix:///var/run/docker.sock')
        @swarm.join_manager(local_connection) if options[:swarm_manager]
        @swarm.join_worker(local_connection) unless options[:swarm_manager]
      end
    end
  end
end
