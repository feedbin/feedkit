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
    request = stub_request_file(file, url)
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
    request = stub_request_file(file, url)
    response = ::Feedkit::Request.download(url)
    assert_equal load_body(file), response.body
  end

  def test_should_raise_invalid_url
    assert_raises Feedkit::InvalidUrl do
      ::Feedkit::Request.download("")
    end
  end

  def test_should_raise_too_large
    url = "http://www.example.com/"
    file = "index.html"

    # build an 11MB string
    body = "12345678910" * (1024 * 1024)
    stub_request(:get, url).to_return(body: body)

    assert_raises Feedkit::TooLarge do
      ::Feedkit::Request.download(url)
    end
  end

  def test_should_raise_not_feed
    url = "http://www.example.com/"
    file = "index.html"
    request = stub_request_file(file, url)
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
        "WWW-Authenticate" => ' Basic realm="Application"'
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
    body = random_string

    response = {
      status: 301,
      headers: {
        "Location" => last_url
      }
    }
    stub_request(:get, first_url).to_return(response)
    stub_request(:get, last_url)

    on_redirect = proc do |_, location|
      @location = location
    end

    response = ::Feedkit::Request.download(first_url, on_redirect: on_redirect)
    assert_equal last_url, @location
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
  end

  def test_should_not_be_modified_etag
    url = "http://www.example.com"
    etag = random_string
    status = 304

    request = {
      headers: {"If-None-Match" => etag}
    }
    stub_request(:get, url).with(request).to_return(status: status)

    assert_raises Feedkit::NotModified do
      ::Feedkit::Request.download(url, etag: etag)
    end
  end

  def test_should_not_be_modified_last_modified
    url = "http://www.example.com"
    last_modified = Time.now.httpdate
    status = 304

    request = {
      headers: {"If-Modified-Since" => last_modified}
    }
    stub_request(:get, url).with(request).to_return(status: status)

    assert_raises Feedkit::NotModified do
      ::Feedkit::Request.download(url, last_modified: last_modified)
    end
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
    request = stub_request_file(file, url)
    response = ::Feedkit::Request.download(url)

    assert_equal "2ff0eb5", response.checksum
  end
end
