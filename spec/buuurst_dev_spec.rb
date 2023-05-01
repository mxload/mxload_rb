# frozen_string_literal: true

require 'json'
require 'securerandom'
require 'uri'

require 'active_support/all'
require 'rails'
require 'rack/test'
require 'webmock/rspec'

require 'test_application'
require 'buuurst_dev/collector'
require 'config/routes'

# rubocop:disable Metrics/BlockLength
RSpec.describe BuuurstDev do
  it 'has a version number' do
    expect(BuuurstDev::VERSION).not_to be nil
  end

  include Rack::Test::Methods
  include TestApplication

  def app
    BuuurstDev::Collector.new(Rails.application)
  end

  BuuurstDev.configuration.custom_header = %w[Content-Type Authorization]

  it 'disable send log' do
    BuuurstDev.configuration.enable = false
    BuuurstDev.configuration.service_key = 'service_key'

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

    BuuurstDev.configuration.enable = true
    BuuurstDev.configuration.service_key = nil
  end

  it 'default put log url is defined' do
    expect(app.instance_variable_get('@put_log_url')).to eq 'https://lambda-public.buuurst.dev/put-request-log'
  end

  it 'can change default put log url' do
    BuuurstDev.configuration.put_log_url = 'http://localtesturl.local/put-request-log'

    expect(app.instance_variable_get('@put_log_url')).to eq 'http://localtesturl.local/put-request-log'

    BuuurstDev.configuration.put_log_url = 'https://lambda-public.buuurst.dev/put-request-log'
  end

  it 'not change get request contents' do
    WebMock.enable!
    stub_request(:any, app.instance_variable_get('@put_log_url'))
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
    stub_request(:any, app.instance_variable_get('@put_log_url'))
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
    BuuurstDev.configuration.service_key = 'service_key'

    path = '/api/get'
    query = 'key1=value1&key2=value2'
    user_agent = 'test-agent'
    cookie = 'key=value'
    uuid = SecureRandom.uuid

    collector = app
    env = Rack::MockRequest.env_for(
      "#{path}?#{query}",
      'HTTP_USER_AGENT' => user_agent,
      'HTTP_COOKIE' => cookie,
      'HTTP_X_REQUEST_ID' => uuid
    )

    collector.get_request_path(env)
    collector.get_request_log(env)

    expect(collector.instance_variable_get('@method')).to eq 'GET'
    expect(collector.instance_variable_get('@path')).to eq path
    expect(collector.instance_variable_get('@query')).to eq Rack::Utils.parse_nested_query(query)
    expect(collector.instance_variable_get('@cookie')).to eq Rack::Utils.parse_cookies_header(cookie)
    expect(collector.instance_variable_get('@request_headers')['HTTP_USER_AGENT']).to eq user_agent
    expect(collector.instance_variable_get('@request_id')).to eq uuid

    BuuurstDev.configuration.service_key = nil
  end

  it 'get request log at POST' do
    BuuurstDev.configuration.service_key = 'service_key'
    path = '/api/post'
    user_id = 'user-id'
    json_str = JSON.generate(key: [{ user_id: user_id }])

    collector = app
    env = Rack::MockRequest.env_for(
      path,
      'REQUEST_METHOD' => 'POST',
      'CONTENT_TYPE' => 'application/json',
      'HTTP_AUTHORIZATION' => 'auth',
      'rack.input' => StringIO.new(json_str)
    )

    collector.get_request_path(env)
    collector.get_request_log(env)

    expect(collector.instance_variable_get('@method')).to eq 'POST'
    expect(collector.instance_variable_get('@path')).to eq path
    expect(collector.instance_variable_get('@request_body')).to eq json_str
    expect(collector.instance_variable_get('@request_headers')).to include(
      'Content-Type' => 'application/json',
      'Authorization' => 'auth'
    )

    BuuurstDev.configuration.service_key = nil
  end

  it 'get response log at GET' do
    collector = app
    uuid = SecureRandom.uuid
    status = 200
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'X-Request-Id' => uuid
    }
    body_str = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Test</title>
        </head>
        <body>
          <h1>Hello, world!</h1>
        </body>
      </html>
    HTML
    body = Rack::BodyProxy.new([body_str])
    collector.get_response_log(status, headers, body)

    expect(collector.instance_variable_get('@request_id')).to eq uuid
    expect(collector.instance_variable_get('@status')).to eq status
    expect(collector.instance_variable_get('@response_headers')).to include(
      'X-Request-Id' => uuid
    )
    expect(collector.instance_variable_get('@response_body')).to eq body_str
  end

  it 'ignore setting path' do
    BuuurstDev.configuration.ignore_paths = %w[/health]

    WebMock.enable!
    stub_request(:any, app.instance_variable_get('@put_log_url'))
      .to_return(body: 'mock', status: 200, headers: {})

    path = '/health'

    collector = app
    env = Rack::MockRequest.env_for(path)

    collector._call(env)

    expect(collector.instance_variable_get('@request_id')).to eq nil
    expect(collector.instance_variable_get('@status')).to eq nil

    BuuurstDev.configuration.ignore_paths = []
  end
end
# rubocop:enable Metrics/BlockLength
