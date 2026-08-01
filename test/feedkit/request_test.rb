require "test_helper"
require "webrick"

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

  def test_should_block_private_addresses
    without_webmock do
      assert_raises Feedkit::BlockedHost do
        ::Feedkit::Request.download("http://127.0.0.1/atom.xml", block_private_addresses: true)
      end
    end
  end

  def test_should_block_hostnames_resolving_to_private_addresses
    without_webmock do
      # blocked on the resolved address, not the literal
      assert_raises Feedkit::BlockedHost do
        ::Feedkit::Request.download("http://localhost/atom.xml", block_private_addresses: true)
      end
    end
  end

  def test_should_not_block_private_addresses_by_default
    url = "http://127.0.0.1/atom.xml"
    stub_request_file("atom.xml", url)

    response = ::Feedkit::Request.download(url)
    assert_instance_of Feedkit::Parser::XMLFeed, response.parse
  end

  def test_should_allow_public_addresses_when_blocking
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)

    response = ::Feedkit::Request.download(url, block_private_addresses: true)
    assert_instance_of Feedkit::Parser::XMLFeed, response.parse
  end

  # Contract test on the http fork: the blocklist must be enforced per
  # connection, so a redirect to a private address is rejected on the hop that
  # reaches it. Feedkit's own criteria block loopback, so this exercises the
  # guarantee with a narrower blocklist that permits the origin server.
  def test_blocklist_is_enforced_on_redirect_hops
    without_webmock do
      server = WEBrick::HTTPServer.new(
        Port: 0,
        Logger: WEBrick::Log.new(File::NULL),
        AccessLog: []
      )
      server.mount_proc("/redirect") do |_request, response|
        response.status = 301
        response["Location"] = "http://10.0.0.1/atom.xml"
      end
      Thread.new { server.start }

      begin
        exception = assert_raises HTTP::BlockedHostError do
          HTTP.blocklist(IPAddr.new("10.0.0.0/8"))
            .follow(max_hops: 4)
            .timeout(connect: 2, write: 2, read: 2)
            .get("http://127.0.0.1:#{server.config[:Port]}/redirect")
        end

        assert_includes exception.message, "10.0.0.1"
      ensure
        server.shutdown
      end
    end
  end

  def test_should_proxy_url
    mock_env("FEEDKIT_PROXIED_HOSTS" => "www.example.com", "FEEDKIT_PROXY_HOST" => "http://proxy.com") do
      request_url = "https://www.example.com/atom.xml"

      proxy_url = "http://proxy.com/atom.xml"
      stub_request_file("atom.xml", proxy_url)

      ::Feedkit::Request.download(request_url)

      assert_requested :get, proxy_url
    end
  end
end
