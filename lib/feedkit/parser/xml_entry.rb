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
        value = {}
        value[:enclosure_type]          = @entry.enclosure_type if @entry.try(:enclosure_type)
        value[:enclosure_url]           = @entry.enclosure_url if @entry.try(:enclosure_url)
        value[:enclosure_length]        = @entry.enclosure_length if @entry.try(:enclosure_length)
        value[:itunes_author]           = @entry.itunes_author if @entry.try(:itunes_author)
        value[:itunes_block]            = @entry.itunes_block if @entry.try(:itunes_block)
        value[:itunes_closed_captioned] = @entry.itunes_closed_captioned if @entry.try(:itunes_closed_captioned)
        value[:itunes_duration]         = @entry.itunes_duration if @entry.try(:itunes_duration)
        value[:itunes_episode]          = @entry.itunes_episode if @entry.try(:itunes_episode)
        value[:itunes_episode_type]     = @entry.itunes_episode_type if @entry.try(:itunes_episode_type)
        value[:itunes_explicit]         = @entry.itunes_explicit if @entry.try(:itunes_explicit)
        value[:itunes_image]            = itunes_image
        value[:itunes_keywords]         = @entry.itunes_keywords if @entry.try(:itunes_keywords)
        value[:itunes_order]            = @entry.itunes_order if @entry.try(:itunes_order)
        value[:itunes_season]           = @entry.itunes_season if @entry.try(:itunes_season)
        value[:itunes_subtitle]         = @entry.itunes_subtitle if @entry.try(:itunes_subtitle)
        value[:itunes_summary]          = @entry.itunes_summary if @entry.try(:itunes_summary)
        value[:itunes_title]            = @entry.itunes_title if @entry.try(:itunes_title)
        value[:youtube_video_id]        = @entry.youtube_video_id if @entry.try(:youtube_video_id)
        value[:media_width]             = @entry.media_width if @entry.try(:media_width)
        value[:media_height]            = @entry.media_height if @entry.try(:media_height)
        value[:public_id_alt]           = public_id_alt if public_id_alt
        value
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
