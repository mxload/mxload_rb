# frozen_string_literal: true

require 'rails/all'

# class TestApplication
#   def call(_env)
#     code = 200
#     body = ['test body']
#     header = {
#       'Content-Type' => 'application/json'
#     }
#     [code, header, body]
#   end
# end

module TestApplication
  class Application < Rails::Application
    config.root = './spec'
    config.time_zone = 'Asia/Tokyo'
    config.eager_load = false
    config.active_support.deprecation = :log
  end

  Rails.application.initialize!
end
