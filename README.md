# Feedkit

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/feedkit`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'feedkit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install feedkit

## Usage

```ruby
response = Feedkit::Request.download(url,
  block_ssrf: true,
  verify_ssl: true,
  timeout: {connect: 5, write: 5, read: 5}
)
```

`FEEDKIT_CURL_HOSTS` is an operator-managed hostname allowlist. Matching hosts
always use curl, taking precedence over `block_ssrf` and HTTP client options.
Curl does not use the checked socket; the allowlist is an explicit trust decision
for those hosts and their redirects.

For other hosts, `block_ssrf: true` checks resolved addresses before connecting,
including each redirect, and refuses private destinations.

`verify_ssl: true` verifies TLS certificates and hostnames. The default remains
`false` for compatibility with existing feed crawlers.

`timeout:` accepts HTTP client `connect`, `write`, and `read` timeouts in seconds.
The defaults are 5, 5, and 30 seconds respectively. These limits apply to the
HTTP client; allowlisted curl requests retain curl's timeout behavior.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/feedbin/feedkit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
