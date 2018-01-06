module Feedkit
  class Tweets

    def initialize(recognized_url, token, secret)
      @recognized_url = recognized_url
      @token = token
      @secret = secret
    end

    def feed
      tweets = client.send(*@recognized_url.client_args).map{|a|a}.reverse
      options = @recognized_url.feed_options.transform_values do |args|
        client.send(*args).to_h
      end
      Parser::TwitterFeed.new(@recognized_url, tweets, options)
    end

    private

    def client
      @client ||= ::Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['TWITTER_KEY']
        config.consumer_secret     = ENV['TWITTER_SECRET']
        config.access_token        = @token
        config.access_token_secret = @secret
      end
    end

  end
end
