#!/usr/bin/bash -xe

cp gitlab-ci/application_template/application_${RAILS_VERSION}.rb spec/config/application.rb

gem install bundler -v 2.3.4
bundle install
