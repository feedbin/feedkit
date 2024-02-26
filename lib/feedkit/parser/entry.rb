# frozen_string_literal: true

module Feedkit
  module Parser
    class Entry
      ENTRY_ATTRIBUTES = Set[:author, :content, :data, :entry_id, :public_id, :published, :title, :url, :categories, :guid]

      attr_reader :entry

      def initialize(entry, feed_url, extra_data = {})
        @entry = entry
        @feed_url = feed_url
        @extra_data = extra_data
      end

      def to_entry
        @to_entry ||= begin
          hash = ENTRY_ATTRIBUTES.each_with_object({}) do |attribute, hash|
            hash[attribute] = respond_to?(attribute) ? send(attribute) : nil
          end
          # don't include dynamic attributes in calculation
          hash[:fingerprint] = Parser.fingerprint_hash(hash)
          hash
        end
      end

      def public_id
        Digest::SHA1.hexdigest(build_id(entry_id))
      end

      def public_id_alt
        Digest::SHA1.hexdigest(build_id(entry_id_alt)) if entry_id_alt
      end

      def guid
        normalized = remove_protocol_and_host(uri: entry_id) unless entry_id.nil?
        normalized = build_id(normalized, compatibility_mode: false)
        Digest::MD5.hexdigest(normalized)
      end

      def fingerprint
        to_entry[:fingerprint]
      end

      def build_id(base_entry_id, compatibility_mode: true)
        parts = []
        parts.push(@feed_url)
        parts.push(base_entry_id)
        unless entry_id
          if compatibility_mode
            parts.push(url)
            parts.push(published.iso8601) if published.respond_to?(:iso8601)
            parts.push(title)
          else
            parts.push(url || title)
          end
        end
        parts.compact.join
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

      def categories
        base = @entry.categories&.respond_to?(:map) ? @entry.categories : []
        base
          .map(&:to_s)
          .map(&:strip)
          .reject(&:empty?)
      end

      private

      def parsed_uri(uri:)
        uri = URI(uri)
        result = [uri.userinfo, uri.path, uri.query, uri.fragment].join
        result == "" ? nil : result
      end

      def remove_protocol_and_host(uri:)
        parsed = URI(uri)
        result = [parsed.userinfo, parsed.path, parsed.query, parsed.fragment].join
        if result == "" || result == "/"
          uri
        else
          result
        end
      rescue
        if uri.respond_to?(:gsub!)
          uri.gsub!("http:", "")
          uri.gsub!("https:", "")
        end
        uri
      end
    end
  end
end
