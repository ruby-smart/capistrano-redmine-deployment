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

          if response['errors']
            log_deploy_errors(response) if log?

            false
          else
            log_deploy_done(response) if log?

            true
          end
        end

        private

        def send_deployment(deployment)
          uri  = URI("#{config.host}/projects/#{config.project}/deploy/#{config.repository}.json")
          http = Net::HTTP.new(uri.host, uri.port)

          request                      = Net::HTTP::Post.new(uri.request_uri)
          request["Content-Type"]      = "application/json"
          request['X-Redmine-API-Key'] = config.api_key
          request.body                 = { deployment: deployment }.to_json

          response = http.request(request)

          begin
            JSON.parse(response.body)
          rescue JSON::ParserError
            {}
          end
        end

        def log_deploy(deployment)
          puts "Sending deployment information to #{config.host} (project: '#{config.project}' repo: '#{config.repository}')"

          puts "   Commits......: #{deployment[:from_revision]} ... #{deployment[:to_revision]}"
          puts "   Environment..: #{deployment[:environment] || '-'}"
          puts "   Branch.......: #{deployment[:branch] || '-'}"
          puts "   Server(s)....: #{deployment[:servers]}"
        end

        def log_deploy_done(response)
          puts "Successfully created deployment ##{response['deployment']['id']}"
        end

        def log_deploy_errors(response)
          puts "Failed to created deployment: #{response['errors'].join(', ')}"
        end
      end
    end
  end
end


