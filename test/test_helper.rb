$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "json"
require "feedkit"

require "minitest/autorun"
require "webmock/minitest"

def stub_request_file(file, url, options = {})
  file = File.join("test", "support", "www", file)
  defaults = {body: File.new(file), status: 200}
  stub_request(:get, url)
    .to_return(defaults.merge(options))
end

def random_string
  (0...50).map { ("a".."z").to_a[rand(26)] }.join
end

def load_body(file)
  File.read(File.join("test", "support", "www", file))
end

# WebMock replaces HTTP::Client#perform, so no connection is ever built and the
# blocklist never runs. Tests that exercise it need the real client.
def without_webmock
  WebMock.disable!
  yield
ensure
  WebMock.enable!
end

def mock_env(partial_env_hash)
  old = ENV.to_hash
  ENV.update partial_env_hash
  begin
    yield
  ensure
    ENV.replace old
  end
end
