# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'active_support/all'

require 'gem_config'

module DietRequestLogger # rubocop:disable Style/Documentation
  include GemConfig::Base

  with_configuration do
    has :enable, default: false
    has :project_id, default: nil
    has :user_key, default: nil
  end

  # send request content and status code for auto loadtest
  class Collector
    PUT_URL = 'https://stg-lambda-public.diet.drev.jp/put-request-log'

    def initialize(app)
      @app = app
      @enable = DietRequestLogger.configuration.enable
      @project_id = DietRequestLogger.configuration.project_id
      @user_key = DietRequestLogger.configuration.user_key
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      get_request_log(env) if @enable
      status, headers, body = @app.call(env)
      if @enable
        get_response_log(status, headers, body)
        send_log
      end
      [status, headers, body]
    end

    def send_log
      url = URI.parse(PUT_URL)
      req_header = { 'Content-Type': 'application/json' }
      param = create_param_json

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.post(url.path, param, req_header)
    end

    # rubocop:disable Metrics/MethodLength
    def create_param_json
      {
        project_id: @project_id,
        requested_at: @time_stamp,
        method: @method,
        path: @path,
        query: @query,
        cookie: @cookie,
        request_id: @request_id,
        status: @status,
        header: @headers,
        user_key: @user_id,
        body: @body
      }.to_json
    end
    # rubocop:enable Metrics/MethodLength

    def get_request_log(env)
      @time_stamp = Time.current.to_i
      @method = env['REQUEST_METHOD']
      @path = env['PATH_INFO']
      @query = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
      @cookie = Rack::Utils.parse_cookies(env)
      get_header(env)
      @request_id = env['HTTP_X_REQUEST_ID']
      get_request_body(env)
      get_user_id(env)
    end

    def get_response_log(status, headers, _body)
      @request_id ||= headers['X-Request-Id']
      @status = status
    end

    private

    def get_header(env)
      @headers = env.select { |k, _v| k.start_with?('HTTP_') }
      @headers['Content-Type'] = env['CONTENT_TYPE'] if env.include?('CONTENT_TYPE')
      @headers.transform_keys! do |k|
        case k
        when 'HTTP_AUTHORIZATION'
          'Authorization'
        else
          k
        end
      end
    end

    def get_request_body(env)
      input = env['rack.input']
      @body = input.gets
      input.rewind
    end

    def get_user_id(env)
      @user_id = env["HTTP_#{@user_key}"] || (@body && find_value_recursive(@user_key, JSON.parse(@body)))
    end

    def find_value_recursive(key, object)
      case object
      when Hash
        find_value_recursive_hash(key, object)
      when Array
        find_value_recursive_array(key, object)
      end
    end

    def find_value_recursive_hash(key, hash)
      return hash[key] if hash.key?(key)

      hash.each do |_k, v|
        res = find_value_recursive(key, v)
        break res if res
      end
    end

    def find_value_recursive_array(key, array)
      array.each do |v|
        res = find_value_recursive(key, v)
        break res if res
      end
    end
  end
end
