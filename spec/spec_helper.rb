# frozen_string_literal: true

require 'capistrano/redmine/deployment/config'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
