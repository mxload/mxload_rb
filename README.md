# Mxload

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mxload', github: 'mxload/mxload_rb' , tag: 'v0.2.3'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install specific_install
    $ gem specific_install -l https://github.com/mxload/mxload_rb.git -b v0.1.4 # use specific_install

## Usage
Write bellow code in config/application.rb ( or config/environments/{RAILS_ENV}.rb ).

    require "mxload/collector"

    config.middleware.insert_before(0, Mxload::Collector)
## Configuration
Create initializer file at config/initializer/mxload.rb and write bellow code.

    Mxload.configure do |config|
        config.enable = true
        config.project_id = 1
        config.service_key = 'servicekey'
        config.put_log_url = 'http://localtesturl.local/put-request-log'
        config.custom_header = %w[Content-Type]
        config.ignore_paths = %w[/health]
    end

- enable
    - used for switching enabled/disabled of this gem
- project_id
    - used for identifying loadtest target app
- service_key
    - used for identifying request user, get at [account info page in Mx.Load](https://app.mxload.mx/accounts)
- put_log_url (optional)
    - used for changing put log destination url
- custom_header (optional)
    - used for logging header contents
- ignore_paths (optional)
    - ignore sending request log when request path is in ignore_paths


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mxload/mxload_rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
