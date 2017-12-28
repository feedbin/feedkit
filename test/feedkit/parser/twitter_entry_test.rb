# encoding: utf-8
require 'test_helper'

class Feedkit::Parser::TwitterEntryTest < Minitest::Test

  def setup
    @tweet = load_tweet
    @parsed_tweet = ::Feedkit::Parser::TwitterEntry.new(@tweet, "https://twitter.com/bsaid")
    @expected = nil
  end

  def test_entry_id
    assert_equal "946202870071820290", @parsed_tweet.entry_id
  end

  def test_author
    assert_equal "Paul Dix", @parsed_tweet.author
  end

  def test_content
    content = <<~EOD
    "Modeling change over time", not just what we should be doing with our time series, but also with our people. Happy to have @<a class="tweet-url username" href="https://twitter.com/TheKaterTot" rel="nofollow">TheKaterTot</a> on board :) <a href="https://t.co/QljAf1YPyF" rel="nofollow" title="https://twitter.com/TheKaterTot/status/946137848498888704"><span class="tco-ellipsis"><span style='position:absolute;left:-9999px;'>&nbsp;</span></span><span style='position:absolute;left:-9999px;'>https://</span><span class="js-display-url">twitter.com/TheKaterTot/st</span><span style='position:absolute;left:-9999px;'>atus/946137848498888704</span><span class="tco-ellipsis"><span style='position:absolute;left:-9999px;'>&nbsp;</span>…</span></a>
    EOD
    assert_equal content.chomp, @parsed_tweet.content
  end

  def test_data
    data = {"tweet" => @tweet.to_h}
    assert_equal data, @parsed_tweet.data
  end

  def test_published
    assert_equal "2017-12-28 02:15:18 UTC", @parsed_tweet.published.to_s
  end

  def test_title
    assert_equal "Paul Dix @pauldix", @parsed_tweet.title
  end

  def test_url
    assert_equal "https://twitter.com/pauldix/status/946202870071820290", @parsed_tweet.url
  end

  def test_to_entry
    assert !!@parsed_tweet.to_entry
  end

  def test_public_id
    assert_equal "be9ffed6b370955e8573f8e4236d480d5278fd35", @parsed_tweet.public_id
  end

  def test_public_id_alt
    assert_equal "be9ffed6b370955e8573f8e4236d480d5278fd35", @parsed_tweet.public_id_alt
  end


end