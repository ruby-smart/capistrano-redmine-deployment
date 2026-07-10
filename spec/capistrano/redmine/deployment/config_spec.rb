# frozen_string_literal: true

require 'tmpdir'
require 'yaml'

RSpec.describe Capistrano::Redmine::Deployment::Config do
  # Minimal capistrano stand-in: `fetch` returns whatever was configured, nil otherwise.
  def fake_capistrano(vars = {})
    Class.new do
      def initialize(vars)
        @vars = vars
      end

      def fetch(key)
        @vars[key]
      end
    end.new(vars)
  end

  # Runs the block with PWD and HOME pointed at isolated temp dirs, so a real
  # `~/.redmine` or a `.redmine` in the repo never leaks into a test.
  def with_isolated_dirs
    Dir.mktmpdir do |pwd|
      Dir.mktmpdir do |home|
        original_home = ENV['HOME']
        ENV['HOME'] = home
        Dir.chdir(pwd) do
          yield(pwd, home)
        end
      ensure
        ENV['HOME'] = original_home
      end
    end
  end

  def write_redmine_file(dir, config)
    File.write(File.join(dir, '.redmine'), YAML.dump(config))
  end

  around do |example|
    # Ensure no leaking ENV between examples.
    keys = %w[REDMINE_API_KEY REDMINE_HOST REDMINE_PROJECT REDMINE_REPOSITORY REDMINE_CA_FILE]
    saved = keys.map { |k| [k, ENV[k]] }
    keys.each { |k| ENV.delete(k) }
    example.run
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  describe '.config_from_env' do
    it 'reads all supported keys from ENV' do
      ENV['REDMINE_API_KEY']    = 'env-key'
      ENV['REDMINE_HOST']       = 'https://env-host'
      ENV['REDMINE_PROJECT']    = 'env-project'
      ENV['REDMINE_REPOSITORY'] = 'env-repo'
      ENV['REDMINE_CA_FILE']    = '/env/ca.pem'

      config = described_class.config_from_env

      expect(config.get(:api_key)).to eq('env-key')
      expect(config.get(:host)).to eq('https://env-host')
      expect(config.get(:project)).to eq('env-project')
      expect(config.get(:repository)).to eq('env-repo')
      expect(config.get(:ca_file)).to eq('/env/ca.pem')
    end

    it 'ignores unset ENV variables' do
      ENV['REDMINE_API_KEY'] = 'only-key'

      config = described_class.config_from_env

      expect(config.get(:api_key)).to eq('only-key')
      expect(config.get(:host)).to be_nil
    end
  end

  describe '.config_from_capistrano' do
    it 'reads the api_key from the :redmine_api_key variable' do
      cap = fake_capistrano(redmine_api_key: 'direct-key')

      config = described_class.config_from_capistrano(cap)

      expect(config.get(:api_key)).to eq('direct-key')
    end

    it 'falls back to the command stdout when :redmine_api_key is unset' do
      cap = fake_capistrano(redmine_api_key_command: 'printf secret-key')

      config = described_class.config_from_capistrano(cap)

      expect(config.get(:api_key)).to eq('secret-key')
    end

    it 'prefers :redmine_api_key over the command' do
      cap = fake_capistrano(redmine_api_key: 'direct-key', redmine_api_key_command: 'printf command-key')

      config = described_class.config_from_capistrano(cap)

      expect(config.get(:api_key)).to eq('direct-key')
    end

    it 'leaves the key unset when the command fails' do
      cap = fake_capistrano(redmine_api_key_command: 'false')

      config = described_class.config_from_capistrano(cap)

      expect(config.get(:api_key)).to be_nil
    end

    it 'leaves the key unset when the command produces empty output' do
      cap = fake_capistrano(redmine_api_key_command: 'true')

      config = described_class.config_from_capistrano(cap)

      expect(config.get(:api_key)).to be_nil
    end
  end

  describe '.resolve precedence' do
    it 'lets ENV win over the .redmine file' do
      with_isolated_dirs do |pwd, _home|
        write_redmine_file(pwd, api_key: 'file-key')
        ENV['REDMINE_API_KEY'] = 'env-key'

        config = described_class.resolve

        expect(config.get(:api_key)).to eq('env-key')
      end
    end

    it 'lets the .redmine file win over the capistrano command' do
      with_isolated_dirs do |pwd, _home|
        write_redmine_file(pwd, api_key: 'file-key')
        cap = fake_capistrano(redmine_api_key_command: 'printf command-key')

        config = described_class.resolve(capistrano: cap)

        expect(config.get(:api_key)).to eq('file-key')
      end
    end

    it 'lets ENV win over the capistrano command' do
      with_isolated_dirs do |_pwd, _home|
        ENV['REDMINE_API_KEY'] = 'env-key'
        cap = fake_capistrano(redmine_api_key_command: 'printf command-key')

        config = described_class.resolve(capistrano: cap)

        expect(config.get(:api_key)).to eq('env-key')
      end
    end

    it 'uses the capistrano command when neither file nor ENV provide a key' do
      with_isolated_dirs do |_pwd, _home|
        cap = fake_capistrano(redmine_api_key_command: 'printf command-key')

        config = described_class.resolve(capistrano: cap)

        expect(config.get(:api_key)).to eq('command-key')
      end
    end

    it 'resolves non-secret keys from ENV as well' do
      with_isolated_dirs do |_pwd, _home|
        ENV['REDMINE_HOST']       = 'https://env-host'
        ENV['REDMINE_PROJECT']    = 'env-project'
        ENV['REDMINE_REPOSITORY'] = 'env-repo'
        ENV['REDMINE_API_KEY']    = 'env-key'

        config = described_class.resolve

        expect(config.valid?).to be(true)
        expect(config.get(:host)).to eq('https://env-host')
      end
    end
  end
end
