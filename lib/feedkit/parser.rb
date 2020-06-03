# frozen_string_literal: true

module Feedkit
  module Parser
    def parse!(file_format, body, url)
      if file_format == "xml"
        Parser::XMLFeed.new(body, url)
      elsif file_format == "json"
        Parser::JSONFeed.new(body, url)
      elsif file_format == "html"
        Nokogiri::HTML(body)
      end
    end
    module_function :parse!
  end
end
