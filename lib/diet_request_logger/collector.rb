# frozen_string_literal: true

module DietRequestLogger
  # send request content and status code for auto loadtest
  class Collector
    def initialize(app)
      @app = app
    end

    def call(env)
      # TODO: envからリクエスト内容の取得
      status, headers, body = @app.call(env)
      # TODO: statusの取得
      # TODO: ログ送信
      [status, headers, body]
    end
  end
end
