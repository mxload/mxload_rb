# frozen_string_literal: true

class ApiController < ActionController::Base
  def get
    render plain: 'test body'
  end

  def post
    render plain: 'test body'
  end
end
