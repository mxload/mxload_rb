# frozen_string_literal: true

require 'json'

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
end
# rubocop:enable Metrics/BlockLength
