# frozen_string_literal: true

module Feedkit
  module Parser
    class JSONEntry < Entry
      def initialize(entry, feed_url, feed_author, feed_authors)
        super(entry, feed_url)
        @feed_author = feed_author
        @feed_authors = feed_authors
      end

      def entry_id
        @entry["id"] ? @entry["id"].to_s.strip : nil
      end

      def author
        @author ||= begin
          value = nil
          value = if @entry["author"] && @entry["author"]["name"]
            @entry["author"]["name"]
          else
            @feed_author
          end
          value
        end
      end

      def authors
        @entry["authors"] || @feed_authors || []
      end

      def content
        @content ||= begin
          value = nil
          if @entry["content_html"]
            value = @entry["content_html"]
          elsif @entry["content_text"]
            value = @entry["content_text"]
          end
          value
        end
      end

      def data
        value = {}
        keys = %w[image banner_image author tag external_url]
        if @entry["attachments"].respond_to?(:first) && @entry["attachments"].first.respond_to?(:[])
          value[:enclosure_type] = @entry["attachments"].first["mime_type"] if @entry["attachments"].first["mime_type"]
          value[:enclosure_url] = @entry["attachments"].first["url"] if @entry["attachments"].first["url"]
          value[:enclosure_length] = @entry["attachments"].first["size_in_bytes"] if @entry["attachments"].first["size_in_bytes"]
          value[:itunes_duration] = @entry["attachments"].first["duration_in_seconds"] if @entry["attachments"].first["duration_in_seconds"]
          value[:title] = @entry["attachments"].first["title"] if @entry["attachments"].first["title"]
        end
        value[:public_id_alt] = public_id_alt if public_id_alt
        value[:json_feed] = @entry.slice(*keys)
        value[:json_feed][:id] = @entry["id"]
        value[:json_feed][:authors] = authors
        value
      end

      def published
        Time.parse(@entry["date_published"])
      rescue
        nil
      end

      def title
        @entry["title"] ? @entry["title"].strip : nil
      end

      def url
        @url = begin
          value = nil
          if @entry["url"]
            value = @entry["url"].strip
          elsif @entry["external_url"]
            value = @entry["external_url"].strip
          end
          value
        end
      end
    end
  end
end
