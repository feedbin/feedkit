require "test_helper"

class Feedkit::Parser::XMLEntryTest < Minitest::Test
  def test_attributes
    feed_url = "http://example.com"
    entry = OpenStruct.new(
      entry_id: "http://example.com/post",
      author: "author",
      content: "content",
      published: Time.now,
      title: "title",
      url: "url"
    )

    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)

    assert_equal(entry.author, parsed_entry.author)
    assert_equal(entry.content, parsed_entry.content)
    assert_equal(entry.published, parsed_entry.published)
    assert_equal(entry.title, parsed_entry.title)
    assert_equal(entry.url, parsed_entry.url)
  end

  def test_public_id_with_entry_id
    feed_url = "http://example.com"
    entry = OpenStruct.new(entry_id: "http://example.com/post", content: "one two")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("27aa8c55201e5701e43a333fe70e2e321be4633c", parsed_entry.public_id)
    assert_equal("6df5d34959dba54ef486861ac2a759a0", parsed_entry.fingerprint)
  end

  def test_public_id_without_entry_id
    feed_url = "http://example.com"
    entry = OpenStruct.new(url: "http://example.com/post", published: Date.parse("2010-10-31"), title: "title")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("65a8274e8ab7f4ae53a3c4f8c9b82f62315c5623", parsed_entry.public_id)
    assert_equal("da01aeb74b762e67363a5593784c41b2", parsed_entry.fingerprint)
  end

  def test_public_id_without_entry_id_and_published
    feed_url = "http://example.com"
    entry = OpenStruct.new(url: "http://example.com/post", published: nil, title: "title")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("4c47ebc1d14231a8202036886fd4a698a0a0baf8", parsed_entry.public_id)
    assert_equal("339270e45af53bf48cf50b0908980316", parsed_entry.fingerprint)
  end

  def test_public_id_without_entry_id_and_published_and_title
    feed_url = "http://example.com"
    entry = OpenStruct.new(url: "http://example.com/post", published: nil, title: nil)
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("27aa8c55201e5701e43a333fe70e2e321be4633c", parsed_entry.public_id)
    assert_equal("f7fc5067d8d8c8f97a79116edd8729ac", parsed_entry.fingerprint)
  end

  def test_public_id_without_entry_id_and_url
    feed_url = "http://example.com"
    entry = OpenStruct.new(url: nil, published: Date.parse("2010-10-31"), title: "title")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("afbda42d0aa9e54a7825e3c1dc5240b6a107581d", parsed_entry.public_id)
    assert_equal("161a8ed792ff929882c0eceb57cc17e8", parsed_entry.fingerprint)
  end

  def test_alternate_entry_id_http
    feed_url = "http://example.com"
    entry = OpenStruct.new(entry_id: "64751@https://wordpress.org/plugins/")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("64751@http://wordpress.org/plugins/", parsed_entry.entry_id_alt)
    assert_equal("b3075ba779825a371a196512d419cdff", parsed_entry.fingerprint)
  end

  def test_alternate_entry_id_https
    feed_url = "http://example.com"
    entry = OpenStruct.new(entry_id: "64751@http://wordpress.org/plugins/")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("64751@https://wordpress.org/plugins/", parsed_entry.entry_id_alt)
    assert_equal("d9d5b9dca1479dc2e3cd4439f51cd913", parsed_entry.fingerprint)
  end

  def test_public_id_alt_with_entry_id_http
    feed_url = "http://example.com/feed.xml"
    entry = OpenStruct.new(entry_id: "http://user:password@foo.com:443/posts?id=30&limit=5#time=1305298413")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("b5c25a8488eb816284f88a87e54eb9f60acc07f0", parsed_entry.public_id_alt)
    assert_equal("8e42940d1c7fe791a560072404171adee3ff4324", parsed_entry.public_id)
    assert_equal("4111ccac3ff462484d2f8be766304a37", parsed_entry.fingerprint)
  end

  def test_public_id_alt_with_port
    feed_url = "http://example.com/feed.xml"
    entry = OpenStruct.new(entry_id: "http://foo.com:443/posts?id=30&limit=5#time=1305298413")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("616839a99ddd9540f8b9e4b1cac743d43e1b8943", parsed_entry.public_id_alt)
    assert_equal("3e998e7374565724769e830c38bcc6576f87edb5", parsed_entry.public_id)
    assert_equal("a32273a55cf866565223f2dd87d57d3e", parsed_entry.fingerprint)
  end
end
