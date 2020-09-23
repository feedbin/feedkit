# frozen_string_literal: true

module Feedkit
  module Parser
    def parse!(body, url:, encoding: Encoding::UTF_8, validate: true)

      result = nil

      feed = Parser::XMLFeed.new(body, url)
      result = feed if feed.valid?

      if !result
        xml = Nokogiri::XML.parse(body.dup.force_encoding(encoding)).to_xml(encoding: "utf-8")
        feed = Parser::XMLFeed.new(xml, url)
        result = feed if feed.valid?
      end

      if !result
        feed = Parser::JSONFeed.new(body, url)
        result = feed if feed.valid?
      end

      if !result && !validate
        feed = Parser::HTMLDocument.new(body)
        result = feed if feed.valid?
      end

      if !result && validate
        raise NotFeed, "result is not a feed"
      end

      result
    end

    module_function :parse!
  end
end
