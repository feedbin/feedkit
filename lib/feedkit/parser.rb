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

    def fingerprint_hash(hash)
      values = []
      deep_flatten(hash) do |value|
        values.push(value.to_s)
      end
      Digest::MD5.hexdigest(values.sort.join)
    end
    module_function :fingerprint_hash

    def deep_flatten(object, &block)
      case object
      when Hash
        object.transform_values { |value| deep_flatten(value, &block) }
      when Array
        object.map { |e| deep_flatten(e, &block) }
      else
        yield(object)
      end
    end
    module_function :deep_flatten

  end
end
