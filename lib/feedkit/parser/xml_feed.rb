# frozen_string_literal: true

module Feedkit
  module Parser
    class XMLFeed < Feed
      def feed
        @feed ||= Feedjira.parse(@body)
      end

      def title
        @title ||= feed.title ? feed.title.strip : "(No title)"
      end

      def site_url
        @site_url ||= begin
          if feed.url
            url = feed.url
          else
            if feed_url =~ /feedburner\.com/ && feed.entries.first.url
              url = last_effective_url(feed.entries.first.url)
              url = url_from_host(url)
            else
              url = url_from_host(feed_url)
            end
          end
          url
        end
      end

      def self_url
        @self_url ||= begin
          url = feed_url
          if feed.self_url
            url = feed.self_url.strip
            unless /^http/.match?(url)
              url = URI.join(feed_url, url).to_s
            end
          end
          url
        rescue
          feed_url
        end
      end

      def hubs
        @hubs = feed.respond_to?(:hubs) ? feed.hubs : []
      end

      def entries
        @entries ||= begin
          entries = []
          if !feed.entries.nil? && feed.entries.length > 0
            entries = feed.entries.map { |entry|
              XMLEntry.new(entry, base_url, {itunes_image: itunes_image})
            }
            entries = entries.uniq { |entry| entry.public_id }
          end
          entries
        end
      end

      def itunes_image
        feed.respond_to?(:itunes_image) && feed.itunes_image ? feed.itunes_image.strip : nil
      end
    end
  end
end
