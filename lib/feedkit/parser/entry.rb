# frozen_string_literal: true

module Feedkit
  module Parser
    class Entry
      ENTRY_ATTRIBUTES = Set[:author, :content, :data, :entry_id, :public_id, :published, :title, :url]

      def initialize(entry, feed_url, extra_data = {})
        @entry = entry
        @feed_url = feed_url
        @extra_data = extra_data
      end

      def to_entry
        @to_entry ||= begin
          ENTRY_ATTRIBUTES.each_with_object({}) do |attribute, hash|
            hash[attribute] = respond_to?(attribute) ? send(attribute) : nil
          end
        end
      end

      def public_id
        @public_id ||= build_id(entry_id)
      end

      def fingerprint
        Parser.fingerprint_hash(to_entry)
      end

      def public_id_alt
        @public_id_alt ||= begin
          if entry_id_alt
            build_id(entry_id_alt)
          end
        end
      end

      def source
        Socket.gethostname
      end

      def entry_id_alt
        @entry_id_alt ||= begin
          if entry_id
            begin
              parsed_uri(entry_id)
            rescue Exception
              if entry_id.include?("http:")
                entry_id.sub("http:", "https:")
              elsif entry_id.include?("https:")
                entry_id.sub("https:", "http:")
              end
            end
          end
        end
      end

      def build_id(base_entry_id)
        parts = []
        parts.push(@feed_url)
        parts.push(base_entry_id)
        unless entry_id
          parts.push(url)
          parts.push(published.iso8601) if published.respond_to?(:iso8601)
          parts.push(title)
        end
        Digest::SHA1.hexdigest(parts.compact.join)
      end

      def parsed_uri(entry_id)
        uri = URI(entry_id)
        result = [uri.userinfo, uri.path, uri.query, uri.fragment].join
        result == "" ? nil : result
      end

    end
  end
end
