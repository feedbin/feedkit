# frozen_string_literal: true

module Feedkit
  module Parser
    class HTMLDocument
      def initialize(body)
        @body = body
      end

      def document
        @document ||= Nokogiri::HTML(@body)
      end

      def valid?
        document.css("link, meta, a").length > 0
      rescue
        false
      end
    end
  end
end
