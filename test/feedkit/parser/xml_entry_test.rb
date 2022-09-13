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
    assert_equal("8f868cbd28d3ff6488671641cbce6183", parsed_entry.fingerprint)
    assert_equal("265e3cdfb549b6402d130caae8b3078e", parsed_entry.guid)
  end

  def test_public_id_without_entry_id
    feed_url = "http://example.com"
    entry = OpenStruct.new(url: "http://example.com/post", published: Date.parse("2010-10-31"), title: "title")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("65a8274e8ab7f4ae53a3c4f8c9b82f62315c5623", parsed_entry.public_id)
    assert_equal("93ff9a08740e7c0dce935045317f2e83", parsed_entry.fingerprint)
    assert_equal("ad18df62a220d9b51c5feabeee39ddf4", parsed_entry.guid)
  end

  def test_public_id_without_entry_id_and_published
    feed_url = "http://example.com"
    entry = OpenStruct.new(url: "http://example.com/post", published: nil, title: "title")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("4c47ebc1d14231a8202036886fd4a698a0a0baf8", parsed_entry.public_id)
    assert_equal("5856d6fd71f6a4c464e4200acab44df5", parsed_entry.fingerprint)
    assert_equal("ad18df62a220d9b51c5feabeee39ddf4", parsed_entry.guid)
  end

  def test_public_id_without_entry_id_and_published_and_title
    feed_url = "http://example.com"
    entry = OpenStruct.new(url: "http://example.com/post", published: nil, title: nil)
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("27aa8c55201e5701e43a333fe70e2e321be4633c", parsed_entry.public_id)
    assert_equal("fb27f4b6cf040f3dd93f9deb64345c1c", parsed_entry.fingerprint)
    assert_equal("6611b142cd5d7d20a3221d4e37fefdf7", parsed_entry.guid)
  end

  def test_public_id_without_entry_id_and_url
    feed_url = "http://example.com"
    entry = OpenStruct.new(url: nil, published: Date.parse("2010-10-31"), title: "title")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("afbda42d0aa9e54a7825e3c1dc5240b6a107581d", parsed_entry.public_id)
    assert_equal("b29e4436db3e53216bd3f32357691f09", parsed_entry.fingerprint)
    assert_equal("d188ac14c6646339bbb8339e91125cfe", parsed_entry.guid)
  end

  def test_alternate_entry_id_http
    feed_url = "http://example.com"
    entry = OpenStruct.new(entry_id: "64751@https://wordpress.org/plugins/")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("64751@http://wordpress.org/plugins/", parsed_entry.entry_id_alt)
    assert_equal("e82b331e29beb47f4a71f4081784873f", parsed_entry.fingerprint)
    assert_equal("59c16ef3165eb0b4ec40bf4e2a52e9d4", parsed_entry.guid)
  end

  def test_entry_id_structure
    feed_url = "http://example.com"
    entry = OpenStruct.new(entry_id: "tag:daringfireball.net,2022:/feeds/sponsors//11.39345")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("a1cfe689ca5aa724b5e3c77ca918a72b", parsed_entry.guid)
    assert_equal("cc8944b052a174ec5c95715c43c776cd", parsed_entry.fingerprint)
  end

  def test_alternate_entry_id_https
    feed_url = "http://example.com"
    entry = OpenStruct.new(entry_id: "64751@http://wordpress.org/plugins/")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("64751@https://wordpress.org/plugins/", parsed_entry.entry_id_alt)
    assert_equal("3c5b0351cc9dfa03098bc2237ca27b9f", parsed_entry.fingerprint)
    assert_equal("59c16ef3165eb0b4ec40bf4e2a52e9d4", parsed_entry.guid)
  end

  def test_public_id_alt_with_entry_id_http
    feed_url = "http://example.com/feed.xml"
    entry = OpenStruct.new(entry_id: "http://user:password@foo.com:443/posts?id=30&limit=5#time=1305298413")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("b5c25a8488eb816284f88a87e54eb9f60acc07f0", parsed_entry.public_id_alt)
    assert_equal("8e42940d1c7fe791a560072404171adee3ff4324", parsed_entry.public_id)
    assert_equal("d3364b92055ac05c60cd403d2d218983", parsed_entry.fingerprint)
    assert_equal("8a3df3552ee132417328010725c71ca2", parsed_entry.guid)
  end

  def test_public_id_alt_with_port
    feed_url = "http://example.com/feed.xml"
    entry = OpenStruct.new(entry_id: "http://foo.com:443/posts?id=30&limit=5#time=1305298413")
    parsed_entry = ::Feedkit::Parser::XMLEntry.new(entry, feed_url)
    assert_equal("616839a99ddd9540f8b9e4b1cac743d43e1b8943", parsed_entry.public_id_alt)
    assert_equal("3e998e7374565724769e830c38bcc6576f87edb5", parsed_entry.public_id)
    assert_equal("77f0b30bce0b2dbdf3841e9564509fa1", parsed_entry.fingerprint)
    assert_equal("b28e137e3cebb985cf0dca2370d6ab90", parsed_entry.guid)
  end
end
