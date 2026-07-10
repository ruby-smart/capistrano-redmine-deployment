# frozen_string_literal: true

require 'net/http'
require 'json'
require 'openssl'

module Capistrano
  module Redmine
    module Deployment
      # HTTP layer that talks to the Redmine-side +redmine_deployment+ plugin.
      #
      # The client POSTs deployment receipts to, and GETs deployment entries
      # from, +{host}/projects/{project}/deploy/{repository}.json+, authenticating
      # with an +X-Redmine-API-Key+ header. A response carrying a +deployment+ key
      # is treated as success; anything else (or an +errors+ array) is a failure.
      #
      # All connection details (host, project, repository, api_key, ca_file,
      # host_verification) are read from the supplied {Config}. SSL is enabled
      # automatically when the host URI uses the +https+ scheme. Console logging
      # is on by default and can be turned off via {#silent!} or the +logging:+
      # initializer flag.
      #
      # @example Log a successful deployment
      #   Client.deploy_success!(config, from_revision: 'abc', to_revision: 'def')
      #
      # @example Verify connectivity without writing anything
      #   Client.receive_deployment(config) # => {"id"=>7, ...}, nil, or false
      class Client

        # @return [Config] the resolved configuration this client reads from.
        attr_reader :config

        class << self
          # Logs a successful deployment.
          #
          # Tags the deployment as +'success'+ and POSTs it to Redmine via a
          # fresh instance.
          #
          # @param config [Config] the resolved configuration.
          # @param deployment [Hash] the deployment payload (mutated in place to
          #   set +:result+).
          # @return [Boolean] +true+ when Redmine accepted the deployment.
          def deploy_success!(config, deployment)
            deployment[:result] = 'success'

            new(config).deploy!(deployment)
          end

          # Logs a failed deployment.
          #
          # Tags the deployment as +'fail'+ and POSTs it to Redmine via a fresh
          # instance.
          #
          # @param config [Config] the resolved configuration.
          # @param deployment [Hash] the deployment payload (mutated in place to
          #   set +:result+).
          # @return [Boolean] +true+ when Redmine accepted the deployment.
          def deploy_fail!(config, deployment)
            deployment[:result] = 'fail'

            new(config).deploy!(deployment)
          end

          # Fetches a single deployment entry to verify connectivity.
          #
          # Convenience wrapper that builds a fresh instance and delegates to
          # {#receive_deployment}.
          #
          # @param config [Config] the resolved configuration.
          # @return [Hash, nil, false] the deployment hash, +nil+ when the
          #   endpoint is reachable but empty, or +false+ on a failed request.
          def receive_deployment(config)
            new(config).receive_deployment
          end
        end

        # @param config [Config] the resolved configuration to read connection
        #   details and credentials from.
        # @param logging [Boolean] whether to print progress to STDOUT
        #   (default +true+). See {#silent!}.
        def initialize(config, logging: true)
          @config = config
          @logging = logging
        end

        # Disables console logging for this client.
        #
        # @return [false]
        def silent!
          @logging = false
        end

        # @return [Boolean] whether console logging is currently enabled.
        def log?
          @logging
        end

        # POSTs a deployment receipt to Redmine.
        #
        # Logs the outgoing deployment, sends it, and reports the outcome. A
        # response containing a +deployment+ key counts as success; anything
        # else is logged as an error.
        #
        # @param deployment [Hash] the deployment payload. Recognized keys
        #   include +:result+, +:from_revision+, +:to_revision+, +:environment+,
        #   +:branch+ and +:servers+.
        # @return [Boolean] +true+ when Redmine created the deployment,
        #   +false+ otherwise.
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

        # Receives a single deployment entry from the redmine repository.
        #
        # Used to verify that the configured credentials / host / project /
        # repository actually resolve to a reachable redmine_deployment endpoint.
        # A successful response with NO entries is still considered valid - it
        # just means no deployment has been logged yet.
        #
        # @return [Hash] the single deployment entry when one exists.
        # @return [nil] when the endpoint is reachable but has no entries yet.
        # @return [false] when the request itself failed (non-2xx / errors).
        def receive_deployment
          response = fetch_deployments

          return false unless response.is_a?(Hash)
          return false if response['errors']

          extract_deployment(response)
        end

        private

        # Builds and performs the POST request carrying the deployment payload.
        #
        # @param deployment [Hash] the deployment payload to serialize as JSON.
        # @return [Hash, String] the parsed JSON response, or the raw body when
        #   it is not valid JSON.
        def send_deployment(deployment)
          uri = deploy_uri

          request = Net::HTTP::Post.new(uri.request_uri)
          request["Content-Type"] = "application/json"
          request['X-Redmine-API-Key'] = config.api_key
          request.body = { deployment: deployment }.to_json

          perform(uri, request)
        end

        # Builds and performs the GET request that fetches deployment entries.
        #
        # Requests only a single entry (+limit=1+) since that is all that is
        # needed to confirm access.
        #
        # @return [Hash, String] the parsed JSON response, or the raw body when
        #   it is not valid JSON.
        def fetch_deployments
          uri = deploy_uri
          # only a single entry is needed to verify access
          uri.query = 'limit=1'

          request = Net::HTTP::Get.new(uri.request_uri)
          request["Content-Type"] = "application/json"
          request['X-Redmine-API-Key'] = config.api_key

          perform(uri, request)
        end

        # Pulls a single deployment out of an index/show response. The
        # redmine_deployment plugin may return either a single +deployment+
        # object or a +deployments+ collection - an empty collection is fine.
        #
        # @param response [Object] the parsed response body.
        # @return [Hash] the +deployment+ object, or the first entry of a
        #   +deployments+ collection.
        # @return [nil] when +response+ is not a hash, or when a +deployments+
        #   collection is empty.
        def extract_deployment(response)
          return nil unless response.is_a?(Hash)

          if response['deployment']
            response['deployment']
          elsif response['deployments']
            response['deployments'].first
          end
        end

        # @return [URI::Generic] the deploy endpoint URI for the configured
        #   host / project / repository.
        def deploy_uri
          URI("#{config.host}/projects/#{config.project}/deploy/#{config.repository}.json")
        end

        # Performs an HTTP request, applying SSL and host-verification settings.
        #
        # SSL is enabled when the URI scheme is +https+. A configured +ca_file+
        # takes precedence; otherwise +host_verification == false+ disables peer
        # verification (the LetsEncrypt/CRL workaround).
        #
        # @param uri [URI::Generic] the request target (supplies host/port/scheme).
        # @param request [Net::HTTPRequest] the prepared request to send.
        # @return [Hash, Array, String] the parsed JSON response, or the raw body
        #   when it is not valid JSON.
        def perform(uri, request)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == 'https'

          if config.ca_file
            http.ca_file = config.ca_file
          elsif config.host_verification == false
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end

          response = http.request(request)

          begin
            JSON.parse(response.body)
          rescue JSON::ParserError
            response.body
          end
        end

        # Prints the outgoing deployment details (and any SSL warnings) to STDOUT.
        #
        # @param deployment [Hash] the deployment payload being sent.
        # @return [void]
        def log_deploy(deployment)
          puts "Sending deployment information to #{config.host} (project: '#{config.project}' | repo: '#{config.repository}')"
          puts "\e[33m   Using custom CA file: #{config.ca_file}\e[0m" if config.ca_file
          puts "\e[33m   WARNING: Host verification disabled!\e[0m" if config.ca_file.nil? && config.host_verification == false
          puts ""
          puts "   Commits......: #{deployment[:from_revision]} ... #{deployment[:to_revision]}"
          puts "   Environment..: #{deployment[:environment] || '-'}"
          puts "   Branch.......: #{deployment[:branch] || '-'}"
          puts "   Server(s)....: #{deployment[:servers]}"
          puts "   Result.......: #{deployment[:result]}"
          puts ""
        end

        # Prints a success line naming the created deployment id.
        #
        # @param response [Hash] the parsed success response.
        # @return [void]
        def log_deploy_done(response)
          puts "\e[32mSuccessfully created deployment ##{response['deployment']['id']}\e[0m"
          puts ""
        end

        # Prints a failure line, listing +errors+ when present or the raw
        # response otherwise.
        #
        # @param response [Object] the parsed failure response.
        # @return [void]
        def log_deploy_errors(response)
          if response['errors']
            puts "\e[31mFailed to created deployment: #{response['errors'].join(', ')}\e[0m"
          else
            puts "\e[31mFailed to created deployment: #{response.inspect}\e[0m"
          end
          puts ""
        end
      end
    end
  end
end
