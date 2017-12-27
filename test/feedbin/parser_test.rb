require "test_helper"

class Feedbin::ParserTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Feedbin::Parser::VERSION
  end

  def test_xml_feed
    url = "http://www.example.com/atom.xml"
    stub_request_file("atom.xml", url)

    result = Feedbin::Parser.fetch_and_parse(url)
    result.to_feed
  end

  def test_json_feed
    url = "http://www.example.com/feed.json"
    stub_request_file("feed.json", url)

    result = Feedbin::Parser.fetch_and_parse(url)
    result.to_feed
  end

end
