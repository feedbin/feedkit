# frozen_string_literal: true

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
      options = @recognized_url.feed_options.transform_values { |args|
        client.send(*args).to_h
      }
      @recognized_url.filters.each do |filter|
        data = filter[:args] ? client.send(*filter[:args]) : nil
        tweets = filter[:proc].call(tweets, data)
      end
      if @recognized_url.title.respond_to?(:call)
        @recognized_url.title = @recognized_url.title.call(client)
      end
      OpenStruct.new(tweets: tweets, options: options)
    end

    private

    def client
      Twitter::REST::Client.new(
        consumer_key: ENV["TWITTER_KEY"],
        consumer_secret: ENV["TWITTER_SECRET"],
        access_token: @token,
        access_token_secret: @secret
      )
    end
  end
end
