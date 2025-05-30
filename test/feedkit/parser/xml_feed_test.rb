require "test_helper"

class Feedkit::Parser::XMLFeedTest < Minitest::Test
  def test_feed_details
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)
    response = ::Feedkit::Request.download(url)
    result = response.parse

    assert_equal "Feedbin", result.title
    assert_equal ["http://pubsubhubbub.superfeedr.com/"], result.hubs
    assert_equal "https://feedbin.com/blog/atom.xml", result.self_url
    assert_equal "https://feedbin.com", result.site_url
    assert_equal 5, result.entries.count
    assert_equal Time.parse("2016-02-03T15:37:25-06:00"), result.entries.first.published
    assert_equal "/2016/02/03/subscribe-to-email-newsletters-in-feedbin", result.entries.first.entry_id
    assert_equal "https://feedbin.com/blog/2016/02/03/subscribe-to-email-newsletters-in-feedbin/", result.entries.first.url
  end

  def test_base_url
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)

    original_url = "http://www.example.com/redirect"
    response = {
      status: 301,
      headers: {
        "Location" => url
      }
    }
    stub_request(:get, original_url).to_return(response)

    response = ::Feedkit::Request.download(original_url)

    # public id should be generated from http://www.example.com/atom.xml
    assert_equal("a6e006a2a819d1dd9186e8f3343fc700e9d0ddf3", response.parse.entries.first.public_id)

    response = ::Feedkit::Request.download(original_url)

    feed = ::Feedkit::Parser.parse!(response.body, url: original_url)

    # public id should be generated from http://www.example.com/redirect
    assert_equal("368ede53b36a81dff3abee0a563f7d5770f4c648", feed.entries.first.public_id)
    assert_equal("6bdb7118689fba5634b7ff7d15e1cc7f", feed.entries.first.fingerprint)
    assert_equal("31b66ce9e7891c7b138782c677d1a012", feed.fingerprint)
  end

  def test_base_url_with_proxy
    mock_env("FEEDKIT_PROXIED_HOSTS" => "www.example.com", "FEEDKIT_PROXY_HOST" => "https://proxy.com") do
      url = "https://proxy.com/atom.xml"
      stub_request_file("atom.xml", url)

      original_url = "http://www.example.com/redirect"
      response = {
        status: 301,
        headers: {
          "Location" => url
        }
      }
      stub_request(:get, "https://proxy.com/redirect").to_return(response)

      response = ::Feedkit::Request.download(original_url)

      # public id should be generated from http://www.example.com/atom.xml
      assert_equal("a6e006a2a819d1dd9186e8f3343fc700e9d0ddf3", response.parse.entries.first.public_id)

      response = ::Feedkit::Request.download(original_url)

      feed = ::Feedkit::Parser.parse!(response.body, url: original_url)

      # public id should be generated from http://www.example.com/redirect
      assert_equal("368ede53b36a81dff3abee0a563f7d5770f4c648", feed.entries.first.public_id)
      assert_equal("6bdb7118689fba5634b7ff7d15e1cc7f", feed.entries.first.fingerprint)
      assert_equal("31b66ce9e7891c7b138782c677d1a012", feed.fingerprint)

      # should be rewritten from proxy
      assert_equal("http://www.example.com/atom.xml", response.request_url)
    end
  end

  def test_base_url_with_password
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)

    original_url = "http://www.example.com/redirect"
    response = {
      status: 301,
      headers: {
        "Location" => url
      }
    }
    stub_request(:get, original_url).to_return(response)

    response = ::Feedkit::Request.download("http://username:password@www.example.com/redirect")

    # public id should be generated from http://username:password@www.example.com/atom.xml
    assert_equal("c653aaeb301aa5428ad9be7780c6a1ea95bd8999", response.parse.entries.first.public_id)
    assert_equal("http://username:password@www.example.com/atom.xml", response.parse.feed_url)

    response = ::Feedkit::Request.download("http://username:password@www.example.com/redirect")

    feed = ::Feedkit::Parser.parse!(response.body, url: original_url)

    # public id should be generated from http://www.example.com/redirect
    assert_equal("368ede53b36a81dff3abee0a563f7d5770f4c648", feed.entries.first.public_id)
    assert_equal("eb6a22d9764315bba8df37c086879cb9", feed.entries.last.fingerprint)
  end
end
