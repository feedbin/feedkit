module Feedkit
  class BasicAuth

    attr_reader :url, :username, :password

    def initialize(data)
      @data = data
    end

    def self.parse(data)
      new(data).parse
    end

    def parse
      uri = @data.to_str.dup.strip
      case uri
      when /^http:\//i
        uri.sub!(/^http:\/+/i, "http://")
      when /^https:\//i
        uri.sub!(/^https:\/+/i, "https://")
      when /^feed:\/+http:\//i
        uri.sub!(/^feed:\/+http:\/+/i, "http://")
      when /^feed:\//i
        uri.sub!(/^feed:\/+/i, "http://")
      when %r[^file:/+]i
        uri.sub!(%r[^file:/+]i, "http://")
      else
        uri = "http://#{uri}"
      end

      uri_parts = uri.split("/")
      host = uri_parts[2]
      if host && host.include?(":") && host.include?("@")
        host_parts = host.split("@")
        credentials = host_parts.shift
        host = host_parts.join("@")

        credentials = credentials.split(":")
        @username = credentials.shift
        @password = credentials.join(":")
      end

      if host
        uri_parts[2] = host
      end


      @url = uri_parts.join("/")

      self
    end


    def username
      decode(@username)
    end

    def password
      decode(@password)
    end

    def decode(data)
      data && URI.unescape(data)
    end

  end
end
