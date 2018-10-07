require 'test_helper'

class Feedkit::Parser::XMLFeedTest < Minitest::Test

  def test_feed_details
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)
    request = ::Feedkit::Request.new(url: url)
    result = ::Feedkit::Parser::XMLFeed.new(request.body, request)

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

    feed = Feedkit::Feedkit.new().fetch_and_parse(original_url, base_url: original_url)

    # public id should be generated from base_url
    assert_equal("368ede53b36a81dff3abee0a563f7d5770f4c648", feed.entries.first.public_id)

    feed = Feedkit::Feedkit.new().fetch_and_parse(original_url)
    assert_equal("a6e006a2a819d1dd9186e8f3343fc700e9d0ddf3", feed.entries.first.public_id)

  end

end