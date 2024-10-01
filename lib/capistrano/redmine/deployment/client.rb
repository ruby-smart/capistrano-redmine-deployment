# frozen_string_literal: true

require 'net/http'
require 'json'

module Capistrano
  module Redmine
    module Deployment
      class Client

        attr_reader :config

        class << self
          def deploy_success!(config, deployment)
            deployment[:result] = 'success'

            new(config).deploy!(deployment)
          end

          def deploy_fail!(config, deployment)
            deployment[:result] = 'fail'

            new(config).deploy!(deployment)
          end
        end

        def initialize(config, logging: true)
          @config  = config
          @logging = logging
        end

        def silent!
          @logging = false
        end

        def log?
          @logging
        end

        def deploy!(deployment)
          log_deploy(deployment) if log?

          response = send_deployment(deployment)

          if response['deployment']
            log_deploy_done(response) if log?

            true
          else
            log_deploy_errors(response) if log?

            false
          end
        end

        private

        def send_deployment(deployment)
          uri  = URI("#{config.host}/projects/#{config.project}/deploy/#{config.repository}.json")

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.port == 443

          request                      = Net::HTTP::Post.new(uri.request_uri)
          request["Content-Type"]      = "application/json"
          request['X-Redmine-API-Key'] = config.api_key
          request.body                 = { deployment: deployment }.to_json

          response = http.request(request)

          begin
            JSON.parse(response.body)
          rescue JSON::ParserError
            response.body
          end
        end

        def log_deploy(deployment)
          puts "Sending deployment information to #{config.host} (project: '#{config.project}' | repo: '#{config.repository}')"

          puts "   Commits......: #{deployment[:from_revision]} ... #{deployment[:to_revision]}"
          puts "   Environment..: #{deployment[:environment] || '-'}"
          puts "   Branch.......: #{deployment[:branch] || '-'}"
          puts "   Server(s)....: #{deployment[:servers]}"
          puts "   Result.......: #{deployment[:result]}"
        end

        def log_deploy_done(response)
          puts "\e[32mSuccessfully created deployment ##{response['deployment']['id']}\e[0m"
        end

        def log_deploy_errors(response)
          if response['errors']
            puts "\e[31mFailed to created deployment: #{response['errors'].join(', ')}\e[0m"
          else
            puts "\e[31mFailed to created deployment: #{response.inspect}\e[0m"
          end

        end
      end
    end
  end
end


