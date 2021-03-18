require "test_helper"

class FeedkitTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Feedkit::VERSION
  end

  def test_xml_feed
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)

    result = ::Feedkit::Request.download(url)
    result.parse
  end

  def test_json_feed
    url = "http://www.example.com/feed.json"
    stub_request_file("feed.json", url)

    result = ::Feedkit::Request.download(url)
    result.parse
  end

  def test_json_feed_1_1
    url = "http://www.example.com/feed.json"
    stub_request_file("feed1_1.json", url)

    result = ::Feedkit::Request.download(url)
    parsed = result.parse

    assert_equal([{"name"=>"Chris Parrish"}], parsed.entries.first.to_entry.dig(:data, :json_feed, :authors))
    assert_equal([{"name"=>"Brent Simmons"}, {"name"=>"Chris Parrish"}], parsed.entries.last.to_entry.dig(:data, :json_feed, :authors))
  end
end
