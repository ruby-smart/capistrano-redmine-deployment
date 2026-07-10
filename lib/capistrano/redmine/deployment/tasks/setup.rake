namespace :capistrano do
  namespace :redmine do
    namespace :deployment do
      desc <<-END_DESC
Configure the redmine credentials for deployment.
      END_DESC

      task :setup do
        require 'capistrano/redmine/deployment/config'

        # resolve configs
        config = Capistrano::Redmine::Deployment::Config.config_from_file(File.join(Dir.pwd, '.redmine'))

        puts "******************************************************************************************************"
        puts "== Capistrano::Redmine::Deployment - setup                                                          =="
        puts "******************************************************************************************************"
        puts ""
        puts " This task creates a '.redmine' file in your current application folder (pwd)."
        puts " Define credentials with this task (e.g. api_key)."
        puts ""
        puts " This file must NOT be exposed and should be EXCLUDED by your scm."
        puts " Define shared settings within your 'config/deploy.rb' (e.g. host, project, repository)."
        puts " Define credentials with this task (e.g. api_key)."
        puts ""
        puts " > HINT: Keep configs empty to prevent to overwrite existing configs."
        puts ""
        puts " > ALTERNATIVE (recommended): the api_key can also be provided without this file"
        puts "   via the ENV variable 'REDMINE_API_KEY' or the capistrano variable"
        puts "   ':redmine_api_key_command' (e.g. a macOS keychain lookup). Both win over"
        puts "   the '.redmine' file. See the README for details."
        puts ""
        puts "******************************************************************************************************"
        puts ""
        puts ""

        # -- BEGIN over here ...

        if config.get(:api_key)
          print "API-KEY (already done)..................> "
        else
          print "API-KEY (optional)......................> "
        end
        redmine_api_key = STDIN.gets.strip

        if config.get(:host)
          print "HOST (already done).....................> "
        else
          print "HOST (optional).........................> "
        end
        redmine_host = STDIN.gets.strip

        if config.get(:project)
          print "PROJECT (already done)..................> "
        else
          print "PROJECT (optional)......................> "
        end
        redmine_project = STDIN.gets.strip

        if config.get(:repository)
          print "REPOSITORY (already done)...............> "
        else
          print "REPOSITORY (optional)...................> "
        end
        redmine_repository = STDIN.gets.strip

        if config.get(:host_verification) != nil
          print "DISABLE HOST VERIFICATION (already done)........> "
        else
          print "DISABLE HOST VERIFICATION (y / n)...............> "
        end
        redmine_host_verification = STDIN.gets.strip

        puts ""


        # force set to overwrite possible existing keys
        config.set(:api_key, redmine_api_key) if redmine_api_key != ''
        config.set(:host, redmine_host) if redmine_host != ''
        config.set(:project, redmine_project) if redmine_project != ''
        config.set(:repository, redmine_repository) if redmine_repository != ''
        config.set(:host_verification, redmine_host_verification.downcase != 'y') if redmine_host_verification != ''

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
