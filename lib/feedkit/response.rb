# frozen_string_literal: true

require "digest"

module Feedkit
  class Response
    attr_reader :path, :redirects

    # tempfile is nil for a 304: there is no body to read, hash, or persist
    def initialize(tempfile:, response:, parsed_url:, redirects:)
      @tempfile   = tempfile
      @path       = tempfile&.path
      @response   = response
      @parsed_url = parsed_url
      @redirects  = redirects
    end

    def body
      @body ||= File.read(@path, binmode: true)
    end

    def parse(validate: true, original_url: nil)
      @parse ||= Parser.parse!(body, url: original_url || url, validate: validate, encoding: encoding)
    end

    def persist!
      unless @path == persisted_path
        FileUtils.mv @path, persisted_path, force: true
        @path = persisted_path
      end
      persisted_path
    end

    # Hashed straight off disk rather than through #body: an unchanged feed is
    # the common case, and reading the file in to hash it would materialize up
    # to MAX_SIZE as a String that nothing goes on to parse.
    def checksum
      @checksum ||= Digest::SHA1.file(@path).hexdigest[0, 7]
    end

    def not_modified?(old_checksum = nil)
      status == 304 || old_checksum == checksum
    end

    def last_modified
      @response.headers.get(:last_modified).last
    end

    def etag
      @response.headers.get(:etag).last
    end

    def headers
      @response.headers
    end

    def url
      result = request_url
      if @parsed_url.username && @parsed_url.password
        parts = result.split("/")
        parts[2] = credentials.to_s + parts[2]
        result = parts.join("/")
      end
      result
    end

    def request_url
      if !@redirects.empty? && @redirects.all?(&:permanent?)
        @redirects.last.to
      else
        @parsed_url.url.to_s
      end
    end

    def credentials
      username = URI.encode_www_form_component(@parsed_url.username)
      password = URI.encode_www_form_component(@parsed_url.password)
      "#{username}:#{password}@"
    end

    def status
      @response.status
    end

    # Most responses don't declare a charset, and Encoding.find(nil) raises, so
    # the nil case is checked rather than rescued: building an exception with a
    # backtrace for the common path is far more expensive than the guard. The
    # rescue stays for charsets that are present but unknown to Ruby.
    def encoding
      charset = @response.content_type.charset
      Encoding.find(charset) if charset
    rescue
      nil
    end

    private

    def persisted_path
      @persisted_path ||= begin
        File.join(Dir.tmpdir, SecureRandom.hex)
      end
    end
  end
end
