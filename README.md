# Capistrano::Redmine::Deployment

[![GitHub](https://img.shields.io/badge/github-ruby--smart/capistrano-redmine-deployment-blue.svg)](http://github.com/ruby-smart/capistrano-redmine-deployment)
[![Documentation](https://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://rubydoc.info/gems/capistrano-redmine-deployment)

[![Gem Version](https://badge.fury.io/rb/capistrano-redmine-deployment.svg?kill_cache=1)](https://badge.fury.io/rb/capistrano-redmine-deployment)
[![License](https://img.shields.io/github/license/ruby-smart/capistrano-redmine-deployment)](docs/LICENSE.txt)

Redmine Deployment Tracking (for redmine_deployment plugin)

_capistrano-redmine-deployment_ is a capistrano task to log deployments to any related redmine repository.
The plugin 'redmine_deployment' is required.

-----

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-redmine-deployment'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install capistrano-redmine-deployment

Configure redmine credentials within your `config/deploy.rb`.
```ruby
# redmine deployment credentials (without api_key)
set(:redmine_host, "https://your-redmine-host")
set(:redmine_project, "target-redmine-project-identifier")
set(:redmine_repository, "target-redmine-repository-identifier")
```

Setup redmine API-KEY through rake-task:

    $ rake capistrano:redmine:deploy:setup


Require deployment tasks within your `Capfile`

    require 'capistrano/redmine/deployment/receipts'

## Redmine requirements

Install the plugin `redmine_deployment`.

## Features
* logs (success/failed) deployment to associated redmine repository

-----

## Docs

[CHANGELOG](docs/CHANGELOG.md)

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/ruby-smart/support).
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](docs/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

A copy of the [LICENSE](docs/LICENSE.md) can be found @ the docs.

## Code of Conduct

Everyone interacting in the project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [CODE OF CONDUCT](docs/CODE_OF_CONDUCT.md).
