module Feedkit
  class BasicAuth

    attr_reader :url

    def initialize(data, username: nil, password: nil)
      @data = data
      @username = decode(username) if username
      @password = decode(password) if password
      @base_username = nil
      @base_password = nil
    end

    def self.parse(*args, **keywords)
      new(*args, **keywords).parse
    end

    def parse
      # strip already returns a fresh String, so the sub! calls below never
      # reach the caller's object and no dup is needed
      uri = @data.to_str.strip
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

      # Credentials only ever live in the authority, so a URI with no "@" at all
      # can't have any. Splitting it would just rebuild an identical string, so
      # the common case skips the round trip entirely.
      if uri.include?("@")
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
      else
        @url = uri
      end

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
