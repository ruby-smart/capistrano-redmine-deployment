# frozen_string_literal: true

require_relative 'capistrano/redmine/deployment/version'
require_relative 'capistrano/redmine/deployment/config'
require_relative 'capistrano/redmine/deployment/client'
require_relative 'capistrano/redmine/deployment/railtie' if defined?(Rails)

module Capistrano
  module Redmine
    module Deployment

    end
  end
end
