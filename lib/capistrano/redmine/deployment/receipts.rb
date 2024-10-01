
require 'capistrano/redmine/deployment/config'
require 'capistrano/redmine/deployment/client'

Capistrano::Configuration.instance(:must_exist).load do

  after 'deploy:create_symlink', 'redmine:log_success_deployment'
  after 'deploy:failed', 'redmine:log_fail_deployment'

  namespace :redmine do
    desc "Logs the success deployment of your redmine repository"
    task :log_success_deployment do
      # resolve redmine config
      config = Capistrano::Redmine::Deployment::Config.resolve(capistrano: self)

      unless config.valid?
        puts "\e[31m    Seems like your redmine configuration is missing or unfinished.\nRun rake task 'rake capistrano:redmine:deployment:setup' to start.\nSkipping redmine deployment.\e[0m"
        next
      end

      if previous_revision == current_revision
        puts "\e[31m    Seems like your old revision & new revision are the same. Skipping redmine deployment.\e[0m"
        next
      end

      # defaults
      set :branch, (respond_to?(:branch) ? branch : 'main')
      if respond_to?(:environment)
        set :environment, environment
      elsif respond_to?(:rails_env)
        set :environment, rails_env
      end

      # create new deployment hash
      deployment = {
        branch:        branch,
        environment:   environment,
        servers:       (roles.values.collect { |r| r.servers }.flatten.collect { |s| s.host }.uniq.join(',') rescue ''),
        from_revision: previous_revision,
        to_revision:   current_revision
      }

      Capistrano::Redmine::Deployment::Client.deploy_success!(config, deployment)
    end

    desc "Logs the fail deployment of your redmine repository"
    task :log_fail_deployment do
      # resolve redmine config
      config = Capistrano::Redmine::Deployment::Config.resolve(capistrano: self)

      unless config.valid?
        puts "\e[31m    Seems like your redmine configuration is missing or unfinished. Skipping redmine deployment.\e[0m"
        next
      end

      if previous_revision == current_revision
        puts "\e[31m    Seems like your old revision & new revision are the same. Skipping redmine deployment.\e[0m"
        next
      end

      # defaults
      set :branch, (respond_to?(:branch) ? branch : 'main')
      if respond_to?(:environment)
        set :environment, environment
      elsif respond_to?(:rails_env)
        set :environment, rails_env
      end

      # create new deployment hash
      deployment = {
        branch:        branch,
        environment:   environment,
        servers:       (roles.values.collect { |r| r.servers }.flatten.collect { |s| s.host }.uniq.join(',') rescue ''),
        from_revision: previous_revision,
        to_revision:   current_revision
      }

      Capistrano::Redmine::Deployment::Client.deploy_fail!(config, deployment)
    end
  end
end