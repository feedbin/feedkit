# frozen_string_literal: true

module Feedkit
  module Parser
    class Entry
      ENTRY_ATTRIBUTES = Set[:author, :content, :data, :entry_id, :public_id, :published, :title, :url, :guid]

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
        Digest::SHA1.hexdigest(build_id(entry_id))
      end

      def public_id_alt
        Digest::SHA1.hexdigest(build_id(entry_id_alt)) if entry_id_alt
      end

      def guid
        normalized = normalize(uri: entry_id) unless entry_id.nil?
        normalized = build_id(normalized, include_published: false)
        Digest::MD5.hexdigest(normalized)
      end

      def fingerprint
        Parser.fingerprint_hash(to_entry)
      end

      def build_id(base_entry_id, include_published: true)
        parts = []
        parts.push(@feed_url)
        parts.push(base_entry_id)
        unless entry_id
          parts.push(url)
          parts.push(published.iso8601) if include_published && published.respond_to?(:iso8601)
          parts.push(title)
        end
        parts.compact.join
      end

      def normalize(uri:)
        parsed_uri(uri: uri)
      rescue
        uri.gsub!("http:", "")
        uri.gsub!("https:", "")
      end

      def parsed_uri(uri:)
        uri = URI(uri)
        result = [uri.userinfo, uri.path, uri.query, uri.fragment].join
        result == "" ? nil : result
      end

      def entry_id_alt
        @entry_id_alt ||= begin
          if entry_id
            begin
              parsed_uri(uri: entry_id)
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

      def source
        Socket.gethostname
      end
    end
  end
end
