# frozen_string_literal: true

require 'rails'

module Capistrano
  module Redmine
    module Deployment
      class Railtie < Rails::Railtie
        railtie_name 'capistrano-redmine-deployment'

        rake_tasks do
          path = File.expand_path(__dir__)
          Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
        end
      end
    end
  end
end


