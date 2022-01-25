# frozen_string_literal: true

Rails.application.routes.draw do
  get 'api/get', to: 'api#get'
  post 'api/post', to: 'api#post'
end
