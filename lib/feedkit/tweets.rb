module Feedkit
  class Tweets

    def initialize(recognized_url, token, secret)
      @recognized_url = recognized_url
      @token = token
      @secret = secret
    end

    def feed
      data = load_data
      Parser::TwitterFeed.new(@recognized_url, data.tweets, data.options)
    end

    def load_data
      tweets = client.send(*@recognized_url.client_args).take(100).to_a.reverse
      options = @recognized_url.feed_options.transform_values do |args|
        client.send(*args).to_h
      end
      @recognized_url.filters.each do |filter|
        data = client.send(*filter[:args])
        tweets = filter[:proc].call(tweets, data)
      end
      OpenStruct.new(tweets: tweets, options: options)
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
