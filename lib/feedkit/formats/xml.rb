# frozen_string_literal: true

module Feedkit
  class Format::XML < Format

    def parse
      Parser::XMLFeed.new(body, url)
    end

    def valid?
      valid = false
      valid = read_data
    rescue Nokogiri::XML::SyntaxError => e
      puts e.code
      puts e.domain
      puts e.to_s
      raise
    end

    def read_data(try_charset: false)
      found = false
      args = [data, nil]
      args.push(@charset) if try_charset
      Nokogiri::XML::Reader(*args).each do |node|
        if !found && ["rss", "atom", "channel", "feed"].include?(node.name)
          found = true
          if try_charset
            @encoding = @charset
          end
        end
      end
      found
    end

  end
end
