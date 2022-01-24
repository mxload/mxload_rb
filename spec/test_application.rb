# frozen_string_literal: true

require_relative 'config/application'
module TestApplication
  class Application < Rails::Application
    config.root = './spec'
    config.time_zone = 'Asia/Tokyo'
    config.eager_load = false
    config.active_support.deprecation = :log
  end

  Rails.application.initialize!
end
