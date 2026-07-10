# frozen_string_literal: true

require 'capistrano/redmine/deployment/client'

RSpec.describe Capistrano::Redmine::Deployment::Client do
  # Minimal config stand-in exposing the keys the client reads.
  def build_config(overrides = {})
    defaults = {
      host:              'https://redmine.example',
      project:           'my-project',
      repository:        'my-repo',
      api_key:           'secret-key',
      host_verification: nil,
      ca_file:           nil
    }
    Capistrano::Redmine::Deployment::Config.new(defaults.merge(overrides))
  end

  # Stubs Net::HTTP so no real request is made. Captures the request object
  # for assertions and returns a fake response whose body is `body`.
  def stub_http(body)
    fake_response = instance_double(Net::HTTPResponse, body: body)
    captured = {}

    http = instance_double(Net::HTTP)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:ca_file=)
    allow(http).to receive(:verify_mode=)
    allow(http).to receive(:request) do |request|
      captured[:request] = request
      fake_response
    end

    allow(Net::HTTP).to receive(:new).and_return(http)
    captured
  end

  subject(:client) { described_class.new(build_config, logging: false) }

  describe '#receive_deployment' do
    it 'issues a GET request with the api-key header' do
      captured = stub_http({ 'deployments' => [] }.to_json)

      client.receive_deployment

      expect(captured[:request]).to be_a(Net::HTTP::Get)
      expect(captured[:request]['X-Redmine-API-Key']).to eq('secret-key')
      expect(captured[:request].path).to eq('/projects/my-project/deploy/my-repo.json?limit=1')
    end

    it 'returns the single deployment from a `deployments` collection' do
      stub_http({ 'deployments' => [{ 'id' => 7 }, { 'id' => 8 }] }.to_json)

      expect(client.receive_deployment).to eq('id' => 7)
    end

    it 'returns the deployment from a single `deployment` object' do
      stub_http({ 'deployment' => { 'id' => 42 } }.to_json)

      expect(client.receive_deployment).to eq('id' => 42)
    end

    it 'returns nil when there are no entries (still a valid response)' do
      stub_http({ 'deployments' => [] }.to_json)

      expect(client.receive_deployment).to be_nil
    end

    it 'returns nil for an empty-but-successful body' do
      stub_http('{}')

      expect(client.receive_deployment).to be_nil
    end

    it 'returns false when the response carries errors' do
      stub_http({ 'errors' => ['forbidden'] }.to_json)

      expect(client.receive_deployment).to be(false)
    end
  end

  describe '.receive_deployment' do
    it 'delegates to a new instance' do
      config = build_config
      stub_http({ 'deployment' => { 'id' => 1 } }.to_json)

      expect(described_class.receive_deployment(config)).to eq('id' => 1)
    end
  end
end
