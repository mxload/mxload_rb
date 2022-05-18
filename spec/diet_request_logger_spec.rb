# frozen_string_literal: true

require 'json'
require 'securerandom'
require 'uri'

require 'active_support/all'
require 'rails'
require 'rack/test'
require 'webmock/rspec'

require 'test_application'
require 'diet_request_logger/collector'
require 'config/routes'

# rubocop:disable Metrics/BlockLength
RSpec.describe DietRequestLogger do
  it 'has a version number' do
    expect(DietRequestLogger::VERSION).not_to be nil
  end

  include Rack::Test::Methods
  include TestApplication

  def app
    DietRequestLogger::Collector.new(Rails.application)
  end

  it 'disable send log' do
    DietRequestLogger.configuration.enable = false
    DietRequestLogger.configuration.user_key = 'user_id'

    path = '/api/get'
    uuid = SecureRandom.uuid

    collector = app
    env = Rack::MockRequest.env_for(
      path,
      'HTTP_X_REQUEST_ID' => uuid
    )

    collector._call(env)

    expect(collector.instance_variable_get('@method')).to eq nil
    expect(collector.instance_variable_get('@path')).to eq nil
    expect(collector.instance_variable_get('@request_id')).to eq nil

    DietRequestLogger.configuration.enable = true
    DietRequestLogger.configuration.user_key = nil
  end

  it 'not change get request contents' do
    WebMock.enable!
    stub_request(:any, DietRequestLogger::Collector::PUT_URL)
      .to_return(body: 'mock', status: 200, headers: {})

    path = '/api/get'
    query = 'key1=value1&key2=value2'
    user_agent = 'test-agent'
    cookie = 'key=value'

    header 'User-Agent', user_agent
    set_cookie(cookie, URI.parse('http://localhost/'))
    get "http://localhost#{path}?#{query}"

    expect(last_request.env['PATH_INFO']).to eq path
    expect(last_request.env['REQUEST_METHOD']).to eq 'GET'
    expect(last_request.env['QUERY_STRING']).to eq query
    expect(last_request.env['HTTP_USER_AGENT']).to eq user_agent
    expect(last_request.cookies).to eq('key' => 'value')

    expect(last_response.status).to eq 200
  end

  it 'not change post request contents' do
    WebMock.enable!
    stub_request(:any, DietRequestLogger::Collector::PUT_URL)
      .to_return(body: 'mock', status: 200, headers: {})

    path = '/api/post'
    json_str = JSON.generate(key: 'value')

    header 'Content-Type', 'application/json'
    post("http://localhost#{path}", json_str)

    expect(last_request.env['PATH_INFO']).to eq path
    expect(last_request.env['REQUEST_METHOD']).to eq 'POST'
    expect(last_request.env['rack.input'].string).to eq json_str

    expect(last_response.status).to eq 200
  end

  it 'get request log at GET' do
    DietRequestLogger.configuration.user_key = 'USER_DATA'

    path = '/api/get'
    query = 'key1=value1&key2=value2'
    user_agent = 'test-agent'
    cookie = 'key=value'
    uuid = SecureRandom.uuid
    user_id = 'user-id'

    collector = app
    env = Rack::MockRequest.env_for(
      "#{path}?#{query}",
      'HTTP_USER_AGENT' => user_agent,
      'HTTP_COOKIE' => cookie,
      'HTTP_X_REQUEST_ID' => uuid,
      'HTTP_USER_DATA' => user_id
    )

    collector.get_request_log(env)

    expect(collector.instance_variable_get('@method')).to eq 'GET'
    expect(collector.instance_variable_get('@path')).to eq path
    expect(collector.instance_variable_get('@query')).to eq Rack::Utils.parse_nested_query(query)
    expect(collector.instance_variable_get('@cookie')).to eq Rack::Utils.parse_cookies_header(cookie)
    expect(collector.instance_variable_get('@headers')['HTTP_USER_AGENT']).to eq user_agent
    expect(collector.instance_variable_get('@request_id')).to eq uuid
    expect(collector.instance_variable_get('@user_id')).to eq user_id

    DietRequestLogger.configuration.user_key = nil
  end

  it 'get request log at POST' do
    DietRequestLogger.configuration.user_key = 'user_id'
    path = '/api/post'
    user_id = 'user-id'
    json_str = JSON.generate(key: [{ user_id: user_id }])

    collector = app
    env = Rack::MockRequest.env_for(
      path,
      'REQUEST_METHOD' => 'POST',
      'HTTP_CONTENT_TYPE' => 'application/json',
      'rack.input' => StringIO.new(json_str)
    )

    collector.get_request_log(env)

    expect(collector.instance_variable_get('@method')).to eq 'POST'
    expect(collector.instance_variable_get('@path')).to eq path
    expect(collector.instance_variable_get('@body')).to eq json_str
    expect(collector.instance_variable_get('@user_id')).to eq user_id

    DietRequestLogger.configuration.user_key = nil
  end

  it 'get response log' do
    collector = app
    uuid = SecureRandom.uuid
    status = 200
    headers = { 'X-Request-Id' => uuid }

    collector.get_response_log(status, headers, {})

    expect(collector.instance_variable_get('@request_id')).to eq uuid
    expect(collector.instance_variable_get('@status')).to eq status
  end
end
# rubocop:enable Metrics/BlockLength
