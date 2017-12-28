require 'test_helper'

class Feedkit::TweetsTest < Minitest::Test

  def test_should_load_tweets
    urls = {
      "https://twitter.com/bsaid"                         => "https://twitter.com/bsaid",
      "@bsaid"                                            => "https://twitter.com/bsaid",
      "https://twitter.com/search?q=feedbin+ben&src=typd" => "https://twitter.com/search?q=feedbin+ben&src=typd",
      "https://twitter.com/bsaid/lists/conversationlist"  => "https://twitter.com/bsaid/lists/conversationlist",
      "https://twitter.com/hashtag/feedbin?src=hash"      => "https://twitter.com/hashtag/feedbin?src=hash",
      "#feedbin"                                          => "https://twitter.com/hashtag/feedbin",
      "twitter.com"                                       => "https://twitter.com?screen_name=bsaid",
    }

    urls.each do |input_url, output_url|
      url = ::Feedkit::TwitterURLRecognizer.new(input_url, "bsaid")

      feed = Feedkit::Tweets.new(url, 'asdf', 'asdf')
      feed.stub :client, TwitterClient.new do
        assert_equal(output_url, feed.feed.feed_url)
        assert !!feed.feed.title
      end
    end
  end

  def test_should_have_feed_properties
    input_url = "https://twitter.com/bsaid"

    url = ::Feedkit::TwitterURLRecognizer.new(input_url, "bsaid")

    feed = Feedkit::Tweets.new(url, 'asdf', 'asdf')
    feed.stub :client, TwitterClient.new do
      assert !!feed.feed.entries

      to_feed = {
        etag: nil,
        feed_url: "https://twitter.com/bsaid",
        last_modified: nil,
        self_url: "https://twitter.com/bsaid",
        site_url: "https://twitter.com/bsaid",
        title: "@bsaid",
        feed_type: :twitter,
        options: { "twitter_user"=>{name: "name"} }
      }
      assert_equal(to_feed, feed.feed.to_feed)
    end
  end

  class TwitterClient
    def user_timeline(*args)
      []
    end

    def user(*args)
      {name: "name"}
    end

    def home_timeline(*args)
      []
    end

    def list_timeline(*args)
      []
    end

    def search(*args)
      []
    end
  end

end
