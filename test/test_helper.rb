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

# WebMock replaces the request before a socket is ever opened, so anything that
# depends on how the connection is made needs a real one.
def real_requests
  WebMock.allow_net_connect!
  yield
ensure
  WebMock.disable_net_connect!
end

def local_server(response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nhi")
  server = TCPServer.new("127.0.0.1", 0)
  thread = Thread.new do
    loop do
      socket = server.accept
      begin
        socket.readpartial(4096)
        socket.write(response)
      rescue
      ensure
        socket.close
      end
    end
  end
  yield server.addr[1]
ensure
  thread&.kill
  server&.close
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
