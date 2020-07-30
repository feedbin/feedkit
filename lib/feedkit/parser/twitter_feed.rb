module Feedkit
  module Parser
    class TwitterFeed

      attr_reader :feed, :entries

      FEED_ATTRIBUTES = %i(etag feed_url last_modified self_url site_url title feed_type options).freeze

      def initialize(recognized_url, tweets, options)
        @recognized_url = recognized_url
        @tweets = tweets
        @url = @recognized_url.url.to_s
        @options = options
      end

      def title
        @recognized_url.title
      end

      def etag
        nil
      end

      def feed_url
        @url
      end

      def last_modified
        nil
      end

      def self_url
        @url
      end

      def site_url
        @url
      end

      def feed_type
        @recognized_url.type
      end

      def options
        @options
      end

      def hubs
        nil
      end

      def entries
        @entries ||= begin
          @tweets.map do |tweet|
            TwitterEntry.new(tweet, @url)
          end
        end
      end

      def to_feed
        @to_feed ||= begin
          FEED_ATTRIBUTES.each_with_object({}) do |attribute, hash|
            hash[attribute] = self.respond_to?(attribute) ? self.send(attribute) : nil
          end
        end
      end

    end
  end
end