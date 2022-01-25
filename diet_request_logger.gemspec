# frozen_string_literal: true

require_relative 'lib/diet_request_logger/version'

Gem::Specification.new do |spec|
  spec.name = 'diet_request_logger'
  spec.version = DietRequestLogger::VERSION
  spec.authors = ['kiichi.koyasu']
  spec.email = ['kiichi.koyasu@drecom.co.jp']

  spec.summary = 'Collecting request log for auto loadtest.'
  spec.description = 'For auto loadtest, collect request data, uri, header, body, etc.'
  spec.homepage = 'https://git.drecom.jp/diet/diet_request_logger'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.metadata['allowed_push_host'] = 'http://gem.drecom.co.jp' if spec.respond_to?(:metadata)
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'gem_config'
  spec.add_dependency 'rack'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'drecom_gem'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'psych', '< 4.0.0'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake'
end
