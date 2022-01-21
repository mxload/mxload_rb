# frozen_string_literal: true

require 'rails/application_controller'

class ApiController < Rails::ApplicationController
  def get
    render plain: 'test body'
  end

  def post
    render plain: 'test body'
  end
end
