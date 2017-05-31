# frozen_string_literal: true

module SPAM
  module COMMANDS
    # Extends Chef Class
    class Chef
      private

      def create_sp
        auth = {
          username: options[:foreman_user],
          password: options[:foreman_password]
        }

        body = {
          name: options[:proxy_name] ? options[:proxy_name] : "#{options[:org]}-chef-proxy",
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
