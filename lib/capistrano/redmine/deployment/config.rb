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

            # try to resolve from capistrano
            config.assign!(config_from_capistrano(capistrano)) if capistrano

            # try to resolve from current PWD
            config.assign!(config_from_file(File.join(Dir.pwd, '.redmine')))
            config.assign!(config_from_file(File.join(ENV['HOME'], '.redmine')))
            config.assign!(config_from_file(file)) if file

            config
          end

          def config_from_capistrano(capistrano)
            config = {
              host:       capistrano.fetch(:redmine_host),
              project:    capistrano.fetch(:redmine_project) || capistrano.fetch(:redmine_project_id),
              repository: capistrano.fetch(:redmine_repository)
            }

            new(config)
          end

          def config_from_file(file)
            new(file: file)
          end
        end

        def initialize(config = {}, file: nil)
          @config = config
          @file   = file
          load
        end

        def set(key, value)
          if value && value != ''
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
            next if !value || value == ''

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


