# frozen_string_literal: true

module DietRequestLogger
  # send request content and status code for auto loadtest
  class Collector
    def initialize(app)
      @app = app
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      get_request_log(env)
      status, headers, body = @app.call(env)
      get_response_log(status, headers, body)
      send_log
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
      @body = env['rack.input'].string
    end

    def get_response_log(status, headers, _body)
      @request_id ||= headers['X-Request-Id']
      @status = status
    end
  end
end
