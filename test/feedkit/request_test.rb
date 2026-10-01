require "test_helper"

class Feedkit::RequestTest < Minitest::Test

  def test_should_be_html
    url = "http://www.example.com/atom.xml"
    body = "<a>hello</a><meta />"
    stub_request(:get, url).to_return(body: body)
    response = ::Feedkit::Request.download(url)
    document = response.parse(validate: false)
    assert_instance_of Feedkit::Parser::HTMLDocument, document
  end

  def test_persistence
    url = "http://www.example.com/"
    file = "index.html"
    stub_request_file(file, url)
    response = ::Feedkit::Request.download(url)

    path_before = response.path

    response.persist!

    assert path_before != response.path, "path should have changed"

    assert File.file?(response.path), "file should exist"

    File.unlink(response.path)
  end

  def test_get_body
    url = "http://www.example.com/"
    file = "index.html"
    stub_request_file(file, url)
    response = ::Feedkit::Request.download(url)
    assert_equal load_body(file), response.body
  end

  def test_should_raise_invalid_url
    assert_raises Feedkit::InvalidUrl do
      ::Feedkit::Request.download("")
    end
  end

  def test_should_raise_not_feed
    url = "http://www.example.com/"
    file = "index.html"
    stub_request_file(file, url)
    response = ::Feedkit::Request.download(url)

    assert_raises Feedkit::NotFeed do
      response.parse
    end
  end

  def test_should_raise_unauthorized
    url = "http://www.example.com/"

    response = {
      status: 401,
      headers: {
        "WWW-Authenticate" => " Basic realm='Application'"
      }
    }
    stub_request(:get, url).to_return(response)

    exception = assert_raises Feedkit::Unauthorized do |e|
      ::Feedkit::Request.download(url)
    end

    assert exception.basic_auth?, "basic_auth? should be true"
  end

  def test_should_raise_too_many_redirects
    first_url = "http://www.example.com"

    urls = {
      first_url => "#{first_url}/one",
      "#{first_url}/one" => "#{first_url}/two",
      "#{first_url}/two" => "#{first_url}/three",
      "#{first_url}/three" => "#{first_url}/four",
      "#{first_url}/four" => "#{first_url}/five"
    }

    urls.each do |url, location|
      response = {
        status: 301,
        headers: {
          "Location" => location
        }
      }
      stub_request(:get, url).to_return(response)
    end

    assert_raises Feedkit::TooManyRedirects do
      ::Feedkit::Request.download(first_url)
    end
  end

  def test_should_raise_invalid_url_on_malformed_redirect
    first_url = "http://www.example.com"

    response = {
      status: 301,
      headers: {
        "Location" => "http://exa mple.com/atom.xml"
      }
    }
    stub_request(:get, first_url).to_return(response)

    assert_raises Feedkit::InvalidUrl do
      ::Feedkit::Request.download(first_url)
    end
  end

  def test_should_raise_invalid_url_on_unparseable_redirect
    first_url = "http://www.example.com"

    response = {
      status: 301,
      headers: {
        "Location" => "http://[/atom.xml"
      }
    }
    stub_request(:get, first_url).to_return(response)

    assert_raises Feedkit::InvalidUrl do
      ::Feedkit::Request.download(first_url)
    end
  end

  def test_should_be_xml
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)
    response = ::Feedkit::Request.download(url)
    assert_instance_of Feedkit::Parser::XMLFeed, response.parse
  end

  def test_should_be_json_feed
    url = "http://www.example.com/feed.json"
    stub_request_file("feed.json", url, {headers: {"Content-Type" => "application/json"}})
    response = ::Feedkit::Request.download(url)

    assert_instance_of Feedkit::Parser::JSONFeed, response.parse
  end

  def test_should_follow_redirects
    first_url = "http://www.example.com"
    last_url = "#{first_url}/final"

    response = {
      status: 301,
      headers: {
        "Location" => last_url
      }
    }
    stub_request(:get, first_url).to_return(response)
    stub_request(:get, last_url)

    response = ::Feedkit::Request.download(first_url)
    assert_equal last_url, response.url
  end

  def test_should_not_follow_temporary_redirects
    first_url = "http://www.example.com"
    last_url = "#{first_url}/final"

    response = {
      status: 302,
      headers: {
        "Location" => last_url
      }
    }
    stub_request(:get, first_url).to_return(response)
    stub_request(:get, last_url)

    response = ::Feedkit::Request.download(first_url)
    assert_equal first_url, response.url
  end

  def test_should_get_caching_headers
    url = "http://www.example.com/atom.xml"
    last_modified = Time.now.httpdate
    etag = random_string

    response = {
      headers: {
        "Last-Modified" => last_modified,
        "Etag" => etag
      }
    }
    stub_request(:get, url).to_return(response)
    response = ::Feedkit::Request.download(url)

    assert_equal last_modified, response.last_modified
    assert_equal etag, response.etag
    assert_equal etag, response.headers.get(:etag).last
  end

  def test_should_not_be_modified_etag
    url = "http://www.example.com"
    etag = random_string
    status = 304

    request = {
      headers: {"If-None-Match" => etag}
    }
    stub_request(:get, url).with(request).to_return(status: status)

    response = ::Feedkit::Request.download(url, etag: etag)
    assert response.not_modified?, "reponse should be not_modified?"
  end

  def test_should_not_be_modified_last_modified
    url = "http://www.example.com"
    last_modified = Time.now.httpdate
    status = 304

    request = {
      headers: {"If-Modified-Since" => last_modified}
    }
    stub_request(:get, url).with(request).to_return(status: status)

    response = ::Feedkit::Request.download(url, last_modified: last_modified)
    assert response.not_modified?, "reponse should be not_modified?"
  end

  def test_should_not_be_modified_checksum
    url = "http://www.example.com"
    stub_request(:get, url)

    response = ::Feedkit::Request.download(url)
    assert response.not_modified?("da39a3e"), "reponse should be not_modified?"
  end

  def test_basic_auth
    request = {
      headers: {"Authorization" => "Basic dXNlcm5hbWU6cGFzc3dvcmQ="}
    }
    stub_request(:get, "http://www.example.com").with(request)

    ::Feedkit::Request.download("http://username:password@www.example.com")
  end

  def test_should_get_checksum
    url = "http://www.example.com/"
    file = "index.html"
    stub_request_file(file, url)
    response = ::Feedkit::Request.download(url)

    assert_equal "2ff0eb5", response.checksum
  end

  def test_should_allow_setting_auto_inflate
    with_auto_inflate = "http://www.example1.com"
    stub_request(:any, with_auto_inflate)
    ::Feedkit::Request.download(with_auto_inflate)

    assert_requested :get, with_auto_inflate, headers: {"Accept-Encoding" => "gzip, deflate"}

    without_auto_inflate = "http://www.example2.com"
    stub_request(:any, without_auto_inflate)
    ::Feedkit::Request.download(without_auto_inflate, auto_inflate: false)

    assert_requested(:get, without_auto_inflate) { |request| request.headers["Accept-Encoding"] == nil }
  end

  def test_should_block_private_address
    real_requests do
      assert_raises Feedkit::PrivateNetworkAddress do
        ::Feedkit::Request.download("http://127.0.0.1/", block_ssrf: true)
      end
    end
  end

  def test_should_block_hostname_resolving_to_private_address
    real_requests do
      assert_raises Feedkit::PrivateNetworkAddress do
        ::Feedkit::Request.download("http://localhost/", block_ssrf: true)
      end
    end
  end

  def test_should_not_block_private_address_by_default
    real_requests do
      local_server do |port|
        response = ::Feedkit::Request.download("http://127.0.0.1:#{port}/")
        assert_equal "hi", response.body
      end
    end
  end

  def test_should_use_curl_for_allowlisted_hosts_even_when_blocking_ssrf
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)
    requested = []

    mock_env("FEEDKIT_CURL_HOSTS" => "www.example.com") do
      Feedkit::Curl.stub(:download, ->(given) { requested << given; :curl_response }) do
        assert_equal :curl_response, Feedkit::Request.download(url, block_ssrf: true)
      end
    end

    assert_equal [url], requested
    assert_not_requested :get, url
  end

  def test_should_still_block_private_hosts_outside_the_curl_allowlist
    mock_env("FEEDKIT_CURL_HOSTS" => "www.example.com") do
      Feedkit::Curl.stub(:download, ->(*) { flunk "host is not allowlisted" }) do
        real_requests do
          assert_raises Feedkit::PrivateNetworkAddress do
            Feedkit::Request.download("http://127.0.0.1/", block_ssrf: true)
          end
        end
      end
    end
  end

  def test_should_keep_curl_available_without_ssrf_protection
    mock_env("FEEDKIT_CURL_HOSTS" => "www.example.com") do
      Feedkit::Curl.stub(:download, :curl_response) do
        assert_equal :curl_response, Feedkit::Request.download("http://www.example.com/atom.xml")
      end
    end
  end

  def test_should_apply_custom_timeouts_without_changing_other_requests
    request = Feedkit::Request.new("https://www.example.com/", timeout: {connect: 2, write: 3, read: 4})
    options = request.client.default_options.timeout_options
    assert_equal 2, options[:connect_timeout]
    assert_equal 3, options[:write_timeout]
    assert_equal 4, options[:read_timeout]
    assert_equal 30, Feedkit::Request.new("https://www.example.com/").client.default_options.timeout_options[:read_timeout]
  end

  def test_partial_timeouts_keep_the_other_default_limits
    request = Feedkit::Request.new("https://www.example.com/", timeout: {read: 4})
    options = request.client.default_options.timeout_options
    assert_equal 5, options[:connect_timeout]
    assert_equal 5, options[:write_timeout]
    assert_equal 4, options[:read_timeout]
  end

  def test_curl_allowlist_takes_precedence_over_http_client_options
    url = "http://www.example.com/"
    stub_request(:get, url).to_return(body: "page")
    mock_env("FEEDKIT_CURL_HOSTS" => "www.example.com") do
      Feedkit::Curl.stub(:download, :curl_response) do
        response = Feedkit::Request.download(url, block_ssrf: true, verify_ssl: true, timeout: {read: 5})
        assert_equal :curl_response, response
      end
    end
    assert_not_requested :get, url
  end

  def test_should_verify_tls_when_requested
    key = OpenSSL::PKey::RSA.new(2048)
    certificate = OpenSSL::X509::Certificate.new
    certificate.version = 2
    certificate.serial = 1
    certificate.subject = certificate.issuer = OpenSSL::X509::Name.parse("/CN=localhost")
    certificate.public_key = key.public_key
    certificate.not_before = Time.now - 60
    certificate.not_after = Time.now + 60
    certificate.sign(key, OpenSSL::Digest.new("SHA256"))
    context = OpenSSL::SSL::SSLContext.new
    context.cert = certificate
    context.key = key
    server = TCPServer.new("127.0.0.1", 0)
    ssl_server = OpenSSL::SSL::SSLServer.new(server, context)
    thread = Thread.new do
      loop do
        socket = nil
        begin
          socket = ssl_server.accept
          socket.readpartial(4096)
          socket.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nhi")
        rescue OpenSSL::SSL::SSLError, IOError
        ensure
          socket&.close
        end
      end
    end

    real_requests do
      url = "https://127.0.0.1:#{server.addr[1]}/"
      assert_raises Feedkit::SSLError do
        Feedkit::Request.download(url, verify_ssl: true)
      end
      assert_equal "hi", Feedkit::Request.download(url).body
    end
  ensure
    thread&.kill
    thread&.join
    server&.close
  end

  # A failing TLS handshake must not switch transports and bypass the check.
  def test_should_not_fall_back_to_curl_on_ssl_error_when_blocking_ssrf
    request = ::Feedkit::Request.new("https://www.example.com/atom.xml", block_ssrf: true)

    request.stub(:request, ->(*) { raise OpenSSL::SSL::SSLError, "unexpected eof while reading" }) do
      ::Feedkit::Curl.stub(:download, ->(*) { flunk "must not reach curl" }) do
        assert_raises ::Feedkit::SSLError do
          request.download
        end
      end
    end
  end

  # Everything a caller can act on arrives as a Feedkit::Error. An SSL failure
  # that isn't the close-without-close_notify case has no curl fallback to take,
  # so it is the one that most easily escapes as a raw OpenSSL error instead.
  def test_should_raise_a_feedkit_error_for_ssl_errors_with_no_curl_fallback
    request = ::Feedkit::Request.new("https://www.example.com/atom.xml")

    request.stub(:request, ->(*) { raise OpenSSL::SSL::SSLError, "decryption failed or bad record mac" }) do
      ::Feedkit::Curl.stub(:download, ->(*) { flunk "must not reach curl" }) do
        exception = assert_raises ::Feedkit::SSLError do
          request.download
        end
        assert_includes exception.message, "decryption failed"
      end
    end
  end

  # Every hop gets its own connection, so the redirect target is checked the
  # same way the original request was. Only a local server can serve the
  # redirect, so the address it listens on is the one hole in the check here.
  def test_should_block_private_address_on_redirect
    first_hop = IPAddr.new("127.0.0.1")

    real_requests do
      redirect = "HTTP/1.1 301 Moved Permanently\r\nLocation: http://127.0.0.2/\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
      local_server(redirect) do |port|
        Feedkit::PrivateAddressCheck.stub(:private_address?, ->(address) { address != first_hop }) do
          exception = assert_raises Feedkit::PrivateNetworkAddress do
            ::Feedkit::Request.download("http://127.0.0.1:#{port}/", block_ssrf: true)
          end

          assert_includes exception.message, "127.0.0.2"
        end
      end
    end
  end

  def test_should_download_when_blocking_ssrf
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)
    response = ::Feedkit::Request.download(url, block_ssrf: true)

    assert_instance_of Feedkit::Parser::XMLFeed, response.parse
  end
end
