# frozen_string_literal: true

module Feedkit
  module Parser
    def parse!(body, url:, encoding: nil, validate: true)

      result = nil

      feed = Parser::XMLFeed.new(body, url)
      result = feed if feed.valid?

      if !result
        detected = DetectEncoding.detect(body)
        encoding = detected.encoding if detected.confident?
        if encoding
          xml = Nokogiri::XML.parse(body, nil, encoding.to_s).to_xml(encoding: "utf-8")
          feed = Parser::XMLFeed.new(xml, url)
          result = feed if feed.valid?
        end
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
