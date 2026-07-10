# frozen_string_literal: true

require 'yaml'

module Capistrano
  module Redmine
    module Deployment
      class Config

        attr_reader :file

        class << self
          def resolve(capistrano: nil, file: nil)
            # build new empty config
            config = new

            # capistrano is the base - files and ENV win over it
            config.assign!(config_from_capistrano(capistrano)) if capistrano

            # try to resolve from current PWD
            config.assign!(config_from_file(File.join(Dir.pwd, '.redmine')))
            config.assign!(config_from_file(File.join(ENV['HOME'], '.redmine')))
            config.assign!(config_from_file(file)) if file

            # ENV wins over files and capistrano
            config.assign!(config_from_env)

            config
          end

          def config_from_capistrano(capistrano)
            config = {
              api_key: capistrano.fetch(:redmine_api_key) || api_key_from_command(capistrano),
              host: capistrano.fetch(:redmine_host),
              project: capistrano.fetch(:redmine_project) || capistrano.fetch(:redmine_project_id),
              repository: capistrano.fetch(:redmine_repository),
              host_verification: capistrano.fetch(:redmine_host_verification),
              ca_file: capistrano.fetch(:redmine_ca_file)
            }

            new(config)
          end

          # Resolves config from ENV variables. Values are filtered by `assign!`,
          # so unset (nil/empty) variables never overwrite an existing value.
          def config_from_env
            new({
              api_key:    ENV['REDMINE_API_KEY'],
              host:       ENV['REDMINE_HOST'],
              project:    ENV['REDMINE_PROJECT'],
              repository: ENV['REDMINE_REPOSITORY'],
              ca_file:    ENV['REDMINE_CA_FILE']
            })
          end

          def config_from_file(file)
            new(file: file)
          end

          private

          # Resolves the api_key by running the `:redmine_api_key_command` capistrano
          # variable (if set) and taking its stdout. This keeps the secret out of
          # `deploy.rb` - only the command (e.g. a keychain lookup) lives there.
          #
          # On any failure (non-zero exit or empty stdout) nil is returned so the
          # file/ENV fallback still applies.
          def api_key_from_command(capistrano)
            cmd = capistrano.fetch(:redmine_api_key_command)
            return nil unless cmd && cmd != ''

            key = `#{cmd}`.strip
            return nil unless $?.success? && !key.empty?

            key
          end
        end

        def initialize(config = {}, file: nil)
          @config = config
          @file = file
          load
        end

        def set(key, value)
          if value != nil && value != ''
            @config[key.to_sym] = value
          else
            @config.delete(key.to_sym)
          end
        end

        def get(key)
          @config[key.to_sym]
        end

        def to_h
          @config
        end

        def assign!(other)
          return unless other

          other.to_h.each do |key, value|
            next if value == nil || value == ''

            set(key, value)
          end
        end

        def valid?
          %i[host project repository api_key].all? { |key|
            val = get(key)
            val && val != ''
          }
        end

        def method_missing(name)
          get(name)
        end

        def save
          return false unless @file

          File.open(@file, 'w') { |f| f.write(YAML.dump(@config)) } rescue false
        end

        def load
          if @file && File.exist?(@file)
            @config = YAML.load_file(@file)
          end
        end
      end
    end
  end
end


