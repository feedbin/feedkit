# frozen_string_literal: true

module Feedkit
  module Parser
    class XMLFeed < Feed
      def feed
        @feed ||= Feedjira.parse(@body)
      end

      def valid?
        !!(feed.url || feed.self_url || feed.title || has_entries?)
      rescue
        false
      end

      def has_entries?
        feed.entries.respond_to?(:length) && feed.entries.length > 0
      end

      def title
        @title ||= feed.title ? feed.title.strip : "(No title)"
      end

      def site_url
        @site_url ||= begin
          if feed.url
            url = feed.url
          else
            url = url_from_host(feed_url)
          end
          url
        end
      end

      def self_url
        url = feed.self_url.strip
        unless /^http/.match?(url)
          url = URI.join(feed_url, url).to_s
        end
        url
      rescue
        nil
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

      def options
        value = {}
        value[:enclosure_type]      = @entry.enclosure_type if @entry.try(:enclosure_type)
        value[:description]         = feed.description if feed.try(:description)
        value[:itunes_author]       = feed.itunes_author if feed.try(:itunes_author)
        value[:itunes_block]        = feed.itunes_block if feed.try(:itunes_block)
        value[:itunes_image]        = feed.itunes_image if feed.try(:itunes_image)
        value[:itunes_explicit]     = feed.itunes_explicit if feed.try(:itunes_explicit)
        value[:itunes_complete]     = feed.itunes_complete if feed.try(:itunes_complete)
        value[:itunes_keywords]     = feed.itunes_keywords if feed.try(:itunes_keywords)
        value[:itunes_type]         = feed.itunes_type if feed.try(:itunes_type)
        value[:itunes_new_feed_url] = feed.itunes_new_feed_url if feed.try(:itunes_new_feed_url)
        value[:itunes_subtitle]     = feed.itunes_subtitle if feed.try(:itunes_subtitle)
        value[:itunes_summary]      = feed.itunes_summary if feed.try(:itunes_summary)
        value[:itunes_categories]   = feed.itunes_categories if feed.try(:itunes_categories)
        value[:youtube_channel_id]  = feed.youtube_channel_id if feed.try(:youtube_channel_id)
        value[:itunes_owners]       = itunes_owners if feed.try(:itunes_owners)
        if feed.try(:image) && !feed.image.try(:url).nil?
          value[:image] = {
            url: feed.image.try(:url)
          }
          value[:image][:description] = feed.image.description if feed.image.try(:description)
          value[:image][:height] = feed.image.height if feed.image.try(:height)
          value[:image][:link] = feed.image.link if feed.image.try(:link)
          value[:image][:title] = feed.image.title if feed.image.try(:title)
          value[:image][:url] = feed.image.url if feed.image.try(:url)
          value[:image][:width] = feed.image.width if feed.image.try(:width)
        end
        value
      end

      def itunes_owners
        feed.respond_to?(:itunes_owners) && feed.itunes_owners.map {|owner| {name: owner.name, email: owner.email} }
      end

      def itunes_image
        feed.respond_to?(:itunes_image) && feed.itunes_image ? feed.itunes_image.strip : nil
      end
    end
  end
end
