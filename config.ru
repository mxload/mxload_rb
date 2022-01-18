# frozen_string_literal: true

# include DietRequestLogger
require_relative 'lib/diet_request_logger/collector'

# rack app for on local
class App
  def call(_env)
    [200, { 'Content-Type' => 'text/plain' }, ['Rack app']]
  end
end

use DietRequestLogger::Collector
run App.new
