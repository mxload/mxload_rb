# frozen_string_literal: true

require 'active_support/all'

require_relative 'lib/buuurst_dev_rb/collector'

# rack app for on local
class App
  def call(_env)
    [200, { 'Content-Type' => 'text/plain' }, ['Rack app']]
  end
end

Time.zone = 'Asia/Tokyo'
use BuuurstDevRb::Collector
run App.new
