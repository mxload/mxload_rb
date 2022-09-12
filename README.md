# BuuurstDevRb

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'buuurst_dev_rb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install buuurst_dev_rb

## Usage
Write bellow code in config/application.rb ( or config/environments/{RAILS_ENV}.rb ).

    require "buuurst_dev_rb/collector"

    config.middleware.insert_before(0, BuuurstDevRb::Collector)
## Configuration
Create initializer file at config/initializer/buuurst_dev_rb.rb and write bellow code.

    BuuurstDevRb.configure do |config|
        config.enable = true
        config.project_id = 1
        config.user_key = 'user'
        config.custom_header = %w[Content-Type]
        config.ignore_paths = %w[/health]
    end

- enable
    - used for switching enabled/disabled of this gem
- project_id
    - used for identifying loadtest target app
- user_key
    - used for finding parameter identifying request user
- cunstom_header (optional)
    - used for logging header contents
- ignore_paths (optional)
    - ignore sending request log when request path is in ignore_paths 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/buuurst_dev_rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
