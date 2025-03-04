# frozen_string_literal: true

require "digest"

module Feedkit
  class Response
    attr_reader :path, :redirects

    def initialize(tempfile:, response:, parsed_url:, redirects:)
      @tempfile   = tempfile
      @path       = tempfile.path
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

    def checksum
      Digest::SHA1.hexdigest(body)[0..6]
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

    def encoding
      Encoding.find(@response.content_type.charset)
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
