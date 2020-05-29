# frozen_string_literal: true

module Feedkit
  module Parser
    class Feed

      attr_reader :feed, :entries

      FEED_ATTRIBUTES = %i(feed_url self_url site_url title options).freeze

      def initialize(body, last_effective_url, base_url = nil)
        @body = body
        @last_effective_url = last_effective_url
        @base_url = base_url
      end

      def feed_url
        @last_effective_url
      end

      def options
      end

      def to_feed
        @to_feed ||= begin
          FEED_ATTRIBUTES.each_with_object({}) do |attribute, hash|
            hash[attribute] = self.respond_to?(attribute) ? self.send(attribute) : nil
          end
        end
      end

      private

      def base_url
        @base_url || @last_effective_url
      end

      def url_from_host(link)
        uri = URI.parse(link)
        URI::HTTP.build(host: uri.host).to_s
      end

      def last_effective_url(url)
        request = HTTP
          .headers(user_agent: "Feedbin")
          .timeout(connect: 5, write: 5, read: 5)
          .follow(max_hops: 4)
          .head(url)
        request.uri.to_s
      end

    end
  end
end