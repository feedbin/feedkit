require "test_helper"

class Feedkit::RequestTest < Minitest::Test
  def test_should_pass_through_base_url
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
    stub_request_file("atom.xml", last_url)

    response = ::Feedkit::Request.download(first_url, base_url: first_url)

    assert_equal first_url, response.base_url
    assert_equal last_url, response.final_url
  end

  def test_persistence
    url = "http://www.example.com/"
    file = "index.html"
    request = stub_request_file(file, url)
    response = ::Feedkit::Request.download(url, validate: false)

    path_before = response.path

    response.persist!

    assert path_before != response.path, "path should have changed"

    assert File.file?(response.path), "file should exist"
  end

  def test_get_body
    url = "http://www.example.com/"
    file = "index.html"
    request = stub_request_file(file, url)
    response = ::Feedkit::Request.download(url, validate: false)
    assert_equal load_body(file), response.body
  end

  def test_should_raise_invalid_url
    assert_raises Feedkit::InvalidUrl do
      ::Feedkit::Request.download("XXX")
    end
  end

  def test_should_raise_too_large
    url = "http://www.example.com/"
    file = "index.html"

    # build an 11MB string
    body = load_body(file) * (1024 * 1024)
    stub_request(:get, url).to_return(body: body)

    assert_raises Feedkit::TooLarge do
      ::Feedkit::Request.download(url, validate: false)
    end
  end

  def test_should_raise_not_supported
    url = "http://www.example.com/image.png"
    stub_request_file("image.png", url)

    assert_raises Feedkit::NotSupported do
      ::Feedkit::Request.download(url, validate: false)
    end
  end

  def test_should_raise_not_feed
    url = "http://www.example.com/"
    file = "index.html"
    request = stub_request_file(file, url)

    assert_raises Feedkit::NotFeed do
      ::Feedkit::Request.download(url)
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
      ::Feedkit::Request.download(first_url, validate: false)
    end
  end

  def test_should_be_xml
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)
    response = ::Feedkit::Request.download(url)
    assert response.xml?, "response should be :xml_feed"
  end

  def test_should_be_json_feed
    url = "http://www.example.com/feed.json"
    stub_request_file("feed.json", url, {headers: {"Content-Type" => "application/json"}})
    response = ::Feedkit::Request.download(url)
    assert response.json?, "response should be :json_feed"
  end

  def test_should_be_html
    url = "http://www.example.com/atom.xml"
    body = "<p>hello</p><p>hello</p>"
    stub_request(:get, url).to_return(body: body)
    response = ::Feedkit::Request.download(url, validate: false)
    assert response.html?, "response should be :html"
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

    response = ::Feedkit::Request.download(first_url, validate: false, on_redirect: on_redirect)
    assert_equal last_url, @location
  end

  def test_should_get_caching_headers
    url = "http://www.example.com/atom.xml"
    last_modified = Time.now
    etag = random_string

    response = {
      headers: {
        "Last-Modified" => last_modified.httpdate,
        "Etag" => etag
      }
    }
    stub_request(:get, url).to_return(response)
    response = ::Feedkit::Request.download(url, validate: false)

    assert_equal last_modified.httpdate, response.last_modified.httpdate
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

    options = ::Feedkit::RequestOptions.new(etag: etag)
    assert_raises Feedkit::NotModified do
      ::Feedkit::Request.download(url, options: options, validate: false)
    end
  end

  def test_should_not_be_modified_last_modified
    url = "http://www.example.com"
    last_modified = Time.now
    status = 304

    request = {
      headers: {"If-Modified-Since" => last_modified.httpdate}
    }
    stub_request(:get, url).with(request).to_return(status: status)

    options = ::Feedkit::RequestOptions.new(last_modified: last_modified)
    assert_raises Feedkit::NotModified do
      ::Feedkit::Request.download(url, options: options, validate: false)
    end
  end

  def test_should_get_charset
    url = "http://www.example.com"
    charset = "utf-8"
    response = {
      headers: {
        "Content-Type" => "text/html; charset=#{charset}"
      }
    }
    stub_request(:get, url).to_return(response)
    response = ::Feedkit::Request.download(url, validate: false)

    assert_equal response.charset, charset
  end

  def test_should_get_checksum
    url = "http://www.example.com/"
    file = "index.html"
    request = stub_request_file(file, url)
    response = ::Feedkit::Request.download(url, validate: false)

    assert_equal "2ff0eb5", response.checksum
  end

  # def test_should_clean_url
  #   samples = {
  #     "www.example.com"          => "http://www.example.com",
  #     "feed://www.example.com"   => "http://www.example.com",
  #     "htp://www.example.com"    => "http://www.example.com",
  #     "htttp://www.example.com"  => "http://www.example.com",
  #     "htps://www.example.com"   => "https://www.example.com",
  #     "htttps://www.example.com" => "https://www.example.com",
  #   }
  #   samples.each do |typo, clean|
  #     feed_request = ::Feedkit::Request.new(url: typo, clean: true)
  #     assert_equal clean, feed_request.url
  #   end
  # end
end
