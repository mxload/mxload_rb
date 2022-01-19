# frozen_string_literal: true

require 'json'
require 'securerandom'

require 'test_application'
require 'rack/test'
require 'diet_request_logger/collector'

# rubocop:disable Metrics/BlockLength
RSpec.describe DietRequestLogger do
  it 'has a version number' do
    expect(DietRequestLogger::VERSION).not_to be nil
  end

  include Rack::Test::Methods
  
  def app
    test_app = TestApplication.new
    DietRequestLogger::Collector.new(test_app)
  end

  DietRequestLogger.configuration.enable = true

  it 'not change get request contents' do
    path = '/api/get'
    query = 'key1=value1&key2=value2'
    user_agent = 'test-agent'
    cookie = 'key=value'

    header 'User-Agent', user_agent
    set_cookie cookie
    get "#{path}?#{query}"

    expect(last_request.env['PATH_INFO']).to eq path
    expect(last_request.env['REQUEST_METHOD']).to eq 'GET'
    expect(last_request.env['QUERY_STRING']).to eq query
    expect(last_request.env['HTTP_USER_AGENT']).to eq user_agent
    expect(last_request.env['HTTP_COOKIE']).to eq cookie

    expect(last_response.status).to eq 200
  end

  it 'not change post request contents' do
    path = '/api/post'
    header = { CONTENT_TYPE: 'application/json' }
    json_str = JSON.generate(key: 'value')

    post(path, json_str, header)
    expect(last_request.env['PATH_INFO']).to eq path
    expect(last_request.env['REQUEST_METHOD']).to eq 'POST'
    expect(last_request.env['rack.input'].string).to eq json_str

    expect(last_response.status).to eq 200
  end

  it 'get request log' do
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
    expect(collector.instance_variable_get('@body')).to eq nil
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
