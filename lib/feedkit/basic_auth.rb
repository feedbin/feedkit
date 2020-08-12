module Feedkit
  class BasicAuth

    attr_reader :url

    def initialize(data, username, password)
      @data = data
      @username = decode(username) if username
      @password = decode(password) if password
    end

    def self.parse(*args)
      new(*args).parse
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

      uri_parts = uri.split("/", -1)
      host = uri_parts[2]
      if host && host.include?("@") && (host.include?(":") || host.include?("%3A") )
        host_parts = host.gsub("%3A", ":").split("@", -1)
        credentials = host_parts.shift
        host = host_parts.join("@")
        credentials = credentials.split(":", -1)
        @base_username = credentials.shift
        @base_password = credentials.join(":")

        uri_parts[2] = host
      end

      @url = uri_parts.join("/")

      self
    end

    def username
      @username ||= decode(@base_username)
    end

    def password
      @password ||= decode(@base_password)
    end

    def decode(data)
      data && URI.decode_www_form_component(data)
    end

  end
end
