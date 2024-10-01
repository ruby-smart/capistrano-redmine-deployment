# frozen_string_literal: true

require_relative 'lib/capistrano/redmine/deployment/version'

Gem::Specification.new do |spec|
  spec.name        = 'capistrano-redmine-deployment'
  spec.version     = Capistrano::Redmine::Deployment.version
  spec.authors     = ['Tobias Gonsior']
  spec.email       = ['info@ruby-smart.org']
  spec.summary     = 'Redmine Deployment Tracking (for redmine_deployment plugin)'
  spec.description = <<~DESC
    'capistrano-redmine-deployment' is a capistrano task to log deployments to any related redmine repository.
    The plugin 'redmine_deployment' is required.
  DESC

  spec.homepage              = 'https://github.com/ruby-smart/capistrano-redmine-deployment'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/ruby-smart/capistrano-redmine-deployment'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/capistrano-redmine-deployment'
  spec.metadata['changelog_uri']     = "#{spec.metadata["source_code_uri"]}/blob/main/docs/CHANGELOG.md"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
