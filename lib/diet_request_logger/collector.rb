# frozen_string_literal: true

require 'gem_config'

module DietRequestLogger
  include GemConfig::Base

  with_configuration do
    has :enable, default: false
    has :app_id, default: nil
    has :user_key, default: nil
  end

  # send request content and status code for auto loadtest
  class Collector
    def initialize(app)
      @app = app
      @enable = DietRequestLogger.configuration.enable
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
      # TODO: 実装
    end

    def get_request_log(env)
      @method = env['REQUEST_METHOD']
      @path = env['PATH_INFO']
      @query = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
      @cookie = Rack::Utils.parse_cookies(env)
      @headers = env.select { |k, _v| k.start_with?('HTTP_') }
      @request_id = env['HTTP_X_REQUEST_ID']
      input = env['rack.input']
      input.rewind
      @body = input.gets
      @user_id = env["HTTP_#{@user_key}"]
    end

    def get_response_log(status, headers, _body)
      @request_id ||= headers['X-Request-Id']
      @status = status
    end
  end
end
