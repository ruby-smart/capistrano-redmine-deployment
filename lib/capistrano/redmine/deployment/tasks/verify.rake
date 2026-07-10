namespace :capistrano do
  namespace :redmine do
    namespace :deployment do
      desc <<-END_DESC
Verify the redmine credentials & access for deployment.
      END_DESC

      task :verify do
        require 'capistrano/redmine/deployment/config'
        require 'capistrano/redmine/deployment/client'

        # resolve configs (from ENV / .redmine file - no capistrano context here)
        config = Capistrano::Redmine::Deployment::Config.resolve

        puts "******************************************************************************************************"
        puts "== Capistrano::Redmine::Deployment - verify                                                         =="
        puts "******************************************************************************************************"
        puts ""
        puts " This task verifies your redmine deployment configuration & access."
        puts " It receives a single deployment entry from the associated redmine repository."
        puts ""
        puts " Shared settings are resolved from ENV or the '.redmine' file (host, project,"
        puts " repository, api_key). Run 'rake capistrano:redmine:deployment:setup' to configure them."
        puts ""
        puts " NOTE: this rake task has no Capistrano context, so 'set(:redmine_host, ...)'"
        puts " values from config/deploy.rb are NOT seen here. To verify using deploy.rb"
        puts " settings, run the stage-aware task instead:  cap <stage> redmine:verify"
        puts ""
        puts "******************************************************************************************************"
        puts ""
        puts ""

        # -- BEGIN over here ...

        unless config.valid?
          puts "\e[31mYour redmine configuration is missing or unfinished.\e[0m"
          puts "Run 'rake capistrano:redmine:deployment:setup' to configure the credentials."
          puts ""
          puts "******************************************************************************************************"
          puts ""
          next
        end

        # An empty result (no deployments logged yet) is fine - `false` means the
        # request itself failed (unreachable host, bad credentials, wrong project/repo).
        result = Capistrano::Redmine::Deployment::Client.receive_deployment(config)

        puts ""
        if result == false
          puts "\e[31mVerification FAILED. Check host, project, repository and api_key.\e[0m"
        else
          puts "\e[32mVerification succeeded.\e[0m"
        end

        puts ""
        puts "******************************************************************************************************"
        puts ""
      end
    end
  end
end
