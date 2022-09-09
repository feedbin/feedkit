# frozen_string_literal: true

module Feedkit
  module Parser
    class Feed
      attr_reader :feed, :entries, :options, :base_url

      FEED_ATTRIBUTES = %i[feed_url self_url site_url title options hubs].freeze

      def initialize(body, base_url)
        @body = body
        @base_url = base_url
      end

      def feed_url
        base_url
      end

      def to_feed
        @to_feed ||= begin
          FEED_ATTRIBUTES.each_with_object({}) do |attribute, hash|
            hash[attribute] = respond_to?(attribute) ? send(attribute) : nil
          end
        end
      end

      def fingerprint
        Parser.fingerprint_hash(to_feed)
      end

      private

      def url_from_host(link)
        uri = URI.parse(link)
        URI::HTTP.build(host: uri.host).to_s
      end
    end
  end
end
