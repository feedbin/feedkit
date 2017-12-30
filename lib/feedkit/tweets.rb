module Feedkit
  class Tweets
    attr_reader :url

    def initialize(recognized_url, token, secret)
      @recognized_url = recognized_url
      @token = token
      @secret = secret
    end

    def feed
      feed_options = {}

      default_options = {
        count: 100,
        tweet_mode: "extended"
      }

      case @recognized_url.type
      when :user
        tweets = client.user_timeline(@recognized_url.value, default_options.merge(exclude_replies: true))
        feed_options["twitter_user"] = client.user(@recognized_url.value).to_h
      when :search
        options = default_options.merge(result_type: "recent", include_entities: true)
        if @recognized_url.value.has_key?(:lang)
          options[:lang] = @recognized_url.value[:lang]
        end
        tweets = client.search(@recognized_url.value[:query], options).map{|a|a}
      when :list
        tweets = client.list_timeline(@recognized_url.value[:user], @recognized_url.value[:list], default_options)
      when :home
        tweets = client.home_timeline(default_options)
        @recognized_url.url.query = "screen_name=#{@recognized_url.value}"
      end

      Parser::TwitterFeed.new(@recognized_url.url.to_s, tweets, @recognized_url.type, @recognized_url.value, feed_options)
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