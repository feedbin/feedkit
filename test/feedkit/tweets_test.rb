require "test_helper"

class Feedkit::TweetsTest < Minitest::Test
  def test_should_load_tweets
    urls = {
      "https://twitter.com/bsaid" => "https://twitter.com/bsaid?screen_name=bsaid",
      "@bsaid" => "https://twitter.com/bsaid?screen_name=bsaid",
      "https://twitter.com/search?q=feedbin+ben&l=en&src=typd" => "https://twitter.com/search?q=feedbin+ben&l=en&src=typd&screen_name=bsaid",
      "https://twitter.com/bsaid/lists/conversationlist" => "https://twitter.com/bsaid/lists/conversationlist?screen_name=bsaid",
      "https://twitter.com/hashtag/feedbin?src=hash" => "https://twitter.com/hashtag/feedbin?src=hash&screen_name=bsaid",
      "#feedbin" => "https://twitter.com/hashtag/feedbin?screen_name=bsaid",
      "twitter.com" => "https://twitter.com?screen_name=bsaid",
      "https://twitter.com/search?f=tweets&q=feedbin%20near%3A%22San%20Francisco%2C%20CA%22&src=typd" => "https://twitter.com/search?f=tweets&q=feedbin+near%3A%22San+Francisco%2C+CA%22&src=typd&screen_name=bsaid"
    }

    urls.each do |input_url, output_url|
      url = ::Feedkit::TwitterURLRecognizer.new(input_url, "bsaid")

      feed = Feedkit::Tweets.new(url, "asdf", "asdf")
      feed.stub :client, TwitterClient.new do
        assert_equal(output_url, feed.feed.feed_url)
        assert !!feed.feed.title
      end
    end
  end

  def test_should_have_list_name
    url = ::Feedkit::TwitterURLRecognizer.new("https://twitter.com/bsaid/lists/conversationlist", "bsaid")
    feed = Feedkit::Tweets.new(url, "asdf", "asdf")
    feed.stub :client, TwitterClient.new do
      assert_equal "Twitter List: bsaid/conversationlist", feed.feed.title
    end
  end

  def test_should_filter_non_matching_tweets
    url = ::Feedkit::TwitterURLRecognizer.new("https://twitter.com/bsaid/lists/conversationlist", "bsaid")
    feed = Feedkit::Tweets.new(url, "asdf", "asdf")
    feed.stub :client, TwitterClient.new do
      assert_equal(1, feed.load_data.tweets.length)
    end
  end

  def test_should_have_feed_properties
    input_url = "https://twitter.com/bsaid"

    url = ::Feedkit::TwitterURLRecognizer.new(input_url, "bsaid")

    feed = Feedkit::Tweets.new(url, "asdf", "asdf")
    feed.stub :client, TwitterClient.new do
      assert !!feed.feed.entries

      to_feed = {
        feed_url: "https://twitter.com/bsaid?screen_name=bsaid",
        self_url: "https://twitter.com/bsaid?screen_name=bsaid",
        site_url: "https://twitter.com/bsaid?screen_name=bsaid",
        title: "@bsaid",
        feed_type: :twitter,
        options: {"twitter_user" => {name: "myname"}}
      }
      assert_equal(to_feed, feed.feed.to_feed)
    end
  end

  class TwitterClient
    def user_timeline(*args)
      []
    end

    def user(*args)
      {name: "myname"}
    end

    def home_timeline(*args)
      []
    end

    def list_timeline(*args)
      [
        OpenStruct.new(
          user: OpenStruct.new(id: 1)
        ),
        OpenStruct.new(
          user: OpenStruct.new(id: 2)
        )
      ]
    end

    def search(*args)
      []
    end

    def list_members(*args)
      [
        OpenStruct.new(id: 1)
      ]
    end
  end
end
