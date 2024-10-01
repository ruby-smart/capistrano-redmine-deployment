namespace :capistrano do
  namespace :redmine do
    namespace :deployment do
      desc <<-END_DESC
Configure the redmine credentials for deployment.
      END_DESC

      task :setup do
        require 'capistrano/redmine/deployment/config'

        puts "******************************************************************************************************"
        puts "== Capistrano::Redmine::Deployment - setup                                                          =="
        puts "******************************************************************************************************"
        puts ""
        puts " This task creates a '.redmine' file in your current application folder (pwd)."
        puts " This file must NOT be exposed and should be EXCLUDED by your scm."
        puts " Define application-related settings within your 'config/deploy.rb' (e.g. host, project, repository)."
        puts " Define authentication-related settings with this task (e.g. api_key)."
        puts ""
        puts "******************************************************************************************************"
        print "REDMINE API-KEY (required)    > "
        redmine_api_key = STDIN.gets.strip
        print "REDMINE HOST (optional)       > "
        redmine_host = STDIN.gets.strip
        print "REDMINE PROJECT (optional)    > "
        redmine_project = STDIN.gets.strip
        print "REDMINE REPOSITORY (optional) > "
        redmine_repository = STDIN.gets.strip
        puts ""

        # build config
        config = Capistrano::Redmine::Deployment::Config.config_from_file(File.join(Dir.pwd, '.redmine'))

        # force set to overwrite possible existing keys
        config.set(:api_key, redmine_api_key)
        config.set(:host, redmine_host)
        config.set(:project, redmine_project)
        config.set(:repository, redmine_repository)

        if config.save
          puts "Successfully stored config @ #{config.file}"
        else
          puts "FAILED to store config @ #{config.file}"
        end

        puts ""
        puts "******************************************************************************************************"
        puts ""
      end
    end
  end
end
