require 'test_helper'

class Feedkit::TwitterFeedTest < Minitest::Test

  class TwitterClient
    def user_timeline(*args)
      []
    end

    def user(*args)
      []
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

  def test_should_load_tweets
    urls = [
      "https://twitter.com/bsaid",
      "@bsaid",
      "https://twitter.com/search?q=feedbin+ben&src=typd",
      "https://twitter.com/bsaid/lists/conversationlist",
      "https://twitter.com/hashtag/feedbin?src=hash",
      "#feedbin",
    ]

    urls.each do |url|
      url = ::Feedkit::TwitterURLRecognizer.new(url, "bsaid")

      feed = Feedkit::TwitterFeed.new(url, 'asdf', 'asdf')
      feed.stub :client, TwitterClient.new do
        feed.feed
      end

    end
  end

end
