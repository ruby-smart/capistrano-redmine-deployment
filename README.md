# Capistrano::Redmine::Deployment

[![GitHub](https://img.shields.io/badge/github-ruby--smart/capistrano--redmine--deployment-blue.svg)](http://github.com/ruby-smart/capistrano-redmine-deployment)
[![Documentation](https://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://rubydoc.info/gems/capistrano-redmine-deployment)

[![Gem Version](https://badge.fury.io/rb/capistrano-redmine-deployment.svg?kill_cache=1)](https://badge.fury.io/rb/capistrano-redmine-deployment)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE.txt)

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

## Setup

Require deployment tasks within your `Capfile`

    require 'capistrano/redmine/deployment/receipts'

-----

## Configuration

### Shared configuration
Configure shared redmine credentials within your `config/deploy.rb`.
```ruby
# redmine deployment credentials (without api_key)
set(:redmine_host, "https://your-redmine-host")
set(:redmine_project, "target-redmine-project-identifier")
set(:redmine_repository, "target-redmine-repository-identifier")

# in case of `SSL` issues that are caused by *CRL* (i.e. by LetsEncrypt certificates)
set(:redmine_host_verification, false)

# alternatively, for instances with a custom CA, point to a CA bundle instead of
# disabling verification entirely (preferred over :redmine_host_verification)
set(:redmine_ca_file, "/path/to/ca-bundle.pem")
```

### User-specific credentials

The `api_key` is resolved from the following sources, **later ones win**:

1. capistrano variables: `:redmine_api_key`, or `:redmine_api_key_command` (its stdout is used as the key) as fallback
2. `.redmine` file in the current directory (`$PWD`) or `$HOME`
3. the `REDMINE_API_KEY` ENV variable

#### Option A: macOS Keychain (recommended)

Store the key once per developer in the keychain (use a dedicated entry):

    $ security add-generic-password -s ri-redmine-deploy -a "$USER" -w 'YOUR_KEY'

Then point capistrano at a command that reads it, in your `config/deploy.rb`:

```ruby
set :redmine_api_key_command, 'security find-generic-password -s ri-redmine-deploy -w'
```

No secret ends up in `deploy.rb` or your SCM — only the command. Once every developer
has switched over, the `.redmine` file can be removed entirely (it stays supported as a
fallback).

> Use a **dedicated** keychain entry (e.g. `ri-redmine-deploy`).

#### Option B: `.redmine` file via rake-task

Setup redmine `API-KEY` through rake-task:

    $ rake capistrano:redmine:deployment:setup


## Verifying the setup

Once configured, verify that the credentials, host, project and repository resolve
to a reachable `redmine_deployment` endpoint:

    $ cap <stage> redmine:verify

This receives a single deployment entry from redmine. A response with **no** entries
(i.e. no deployment has been logged yet) still counts as a success — it only fails
when the host is unreachable or the credentials / project / repository are wrong.

## Redmine requirements

Install the plugin `redmine_deployment`.

## Features
* logs (success/failed) deployment to associated redmine repository
* verifies redmine access / configuration (`redmine:verify`)

-----

## Docs

[CHANGELOG](docs/CHANGELOG.md)

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/ruby-smart/capistrano-redmine-deployment).
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](docs/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

A copy of the [LICENSE](LICENSE.txt) can be found @ the docs.

## Code of Conduct

Everyone interacting in the project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [CODE OF CONDUCT](docs/CODE_OF_CONDUCT.md).
