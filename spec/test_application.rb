# frozen_string_literal: true

class TestApplication
  def call(_env)
    code = 200
    body = ['test body']
    header = {
      'Content-Type' => 'application/json'
    }
    [code, header, body]
  end
end
