# frozen_string_literal: true

module Feedkit
  module Parser
    def parse!(body, url:, validate: true)

      result = nil

      feed = Parser::XMLFeed.new(body, url)
      result = feed if feed.valid?

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
