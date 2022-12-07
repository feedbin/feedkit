# frozen_string_literal: true

module Feedkit
  module Parser
    class XMLEntry < Entry
      def entry_id
        @entry.entry_id ? @entry.entry_id.strip : nil
      end

      def author
        @author ||= begin
          value = nil
          if @entry.try(:author)
            value = @entry.author
          elsif @entry.try(:itunes_author)
            value = @entry.itunes_author
          end
          value
        end
      end

      def content
        @content ||= begin
          value = nil
          if entry_has?(:content)
            value = @entry.content
          elsif entry_has?(:summary)
            value = @entry.summary
          elsif entry_has?(:description)
            value = @entry.description
          elsif entry_has?(:media_description)
            value = @entry.media_description
          end
          value
        end
      end

      def entry_has?(attribute)
        @entry.try(attribute) && @entry.try(attribute).strip != ""
      end

      def data
        attributes = %i[
          enclosure_length
          enclosure_type
          enclosure_url
          itunes_author
          itunes_block
          itunes_closed_captioned
          itunes_duration
          itunes_episode
          itunes_episode_type
          itunes_explicit
          itunes_keywords
          itunes_order
          itunes_season
          itunes_subtitle
          itunes_summary
          itunes_title
          media_height
          media_width
          youtube_video_id
        ]

        hash = extract_attributes(@entry, attributes)

        hash[:media]         = media         if media
        hash[:itunes_image]  = itunes_image  if itunes_image
        hash[:public_id_alt] = public_id_alt if public_id_alt
        hash
      end

      def published
        @entry.published
      end

      def title
        @entry.title ? @entry.title.strip : nil
      end

      def url
        @entry.url ? @entry.url.strip : nil
      end

      def media
        return unless @entry.try(:media).respond_to?(:each)
        attributes = %i[
          star_average
          star_count
          thumbnail_height
          thumbnail_url
          thumbnail_width
          title
          type
          url
        ]

        @entry.media.each_with_object([]) do |media, array|
          array.push(extract_attributes(media, attributes))
        end
      end

      def extract_attributes(object, attributes)
        attributes.each_with_object({}) do |attribute, hash|
          if value = object.try(attribute)
            hash[attribute] = value.respond_to?(:strip) ? value.strip : value
          end
        end
      end

      def itunes_image
        if @entry.try(:itunes_image)
          @entry.itunes_image.strip
        elsif !@extra_data[:itunes_image].nil?
          @extra_data[:itunes_image].strip
        end
      end
    end
  end
end
