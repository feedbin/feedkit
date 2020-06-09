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
  end
end
