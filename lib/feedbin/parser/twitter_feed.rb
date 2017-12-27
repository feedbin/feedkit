module Feedbin
  module Parser
    class TwitterFeed
      attr_reader :url

      def initialize(recognized_url, token, secret)
        @recognized_url = recognized_url
        @token = token
        @secret = secret
      end

      def feed
        type = nil
        tweets = nil
        options = {}
        url = nil

        default_options = {
          count: 100,
          tweet_mode: "extended"
        }

        case @recognized_url.type
        when :user
          type = :user
          tweets = client.user_timeline(@recognized_url.value, default_options.merge(exclude_replies: true))
          options["twitter_user"] = client.user(@recognized_url.value)
        when :search
          type = :search
          tweets = client.search(@recognized_url.value, default_options.merge(result_type: "recent", include_entities: true)).map{|a|a}
        when :list
          type = :list
          tweets = client.list_timeline(@recognized_url.value[:user], @recognized_url.value[:list], default_options)
        when :home
          type = :home
          tweets = client.home_timeline(default_options)
          @url.query = "screen_name=#{@recognized_url.value}"
        end

        ParsedTwitterFeed.new(@url.to_s, tweets, @recognized_url.type, @recognized_url.value, options)
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
end