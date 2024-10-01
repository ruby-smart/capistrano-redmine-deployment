require 'capistrano/redmine/deployment/config'
require 'capistrano/redmine/deployment/client'

after 'deploy:cleanup', 'redmine:log_success_deployment'
after 'deploy:failed', 'redmine:log_fail_deployment'

namespace :redmine do
  desc "Logs the success deployment of your redmine repository"
  task :log_success_deployment do
    run_locally do
      # resolve redmine config
      config = Capistrano::Redmine::Deployment::Config.resolve(capistrano: self)

      unless config.valid?
        puts "\e[31m    Seems like your redmine configuration is missing or unfinished.\n    Run rake task 'rake capistrano:redmine:deployment:setup' to start.\n    Skipping redmine deployment.\e[0m"
        next
      end

      # resolve configs
      previous_revision = fetch(:previous_revision)
      current_revision  = fetch(:current_revision)
      environment       = fetch(:stage) || fetch(:environment)
      branch            = fetch(:branch) || 'main'
      roles             = roles(:all)

      if previous_revision == current_revision
        puts "\e[31m    Seems like your old revision & new revision are the same. Skipping redmine deployment.\e[0m"
        next
      end

      # create new deployment hash
      deployment = {
        branch:        branch,
        environment:   environment,
        servers:       (roles.map { |r| r.hostname }.uniq.join(',') rescue ''),
        from_revision: previous_revision,
        to_revision:   current_revision
      }

      Capistrano::Redmine::Deployment::Client.deploy_success!(config, deployment)
    end
  end

  desc "Logs the fail deployment of your redmine repository"
  task :log_fail_deployment do
    run_locally do
      # resolve redmine config
      config = Capistrano::Redmine::Deployment::Config.resolve(capistrano: self)

      unless config.valid?
        puts "\e[31m    Seems like your redmine configuration is missing or unfinished.\n    Run rake task 'rake capistrano:redmine:deployment:setup' to start.\n    Skipping redmine deployment.\e[0m"
        next
      end

      # resolve configs
      previous_revision = fetch(:previous_revision)
      current_revision  = fetch(:current_revision)
      environment       = fetch(:stage) || fetch(:environment)
      branch            = fetch(:branch) || 'main'
      roles             = roles(:all)

      # create new deployment hash
      deployment = {
        branch:        branch,
        environment:   environment,
        servers:       (roles.map { |r| r.hostname }.uniq.join(',') rescue ''),
        from_revision: previous_revision,
        to_revision:   current_revision
      }

      Capistrano::Redmine::Deployment::Client.deploy_fail!(config, deployment)
    end
  end
end