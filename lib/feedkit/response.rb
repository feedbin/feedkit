# frozen_string_literal: true

require "digest"

module Feedkit
  class Response
    attr_reader :path

    def initialize(tempfile:, response:, parsed_url:)
      @tempfile   = tempfile
      @path       = tempfile.path
      @response   = response
      @parsed_url = parsed_url
    end

    def body
      @body ||= File.read(@path, binmode: true)
    end

    def parse(validate: true)
      @parse ||= Parser.parse!(body, url: url, validate: validate)
    end

    def not_modified?(old_checksum = nil)
      status == 304 || old_checksum == checksum
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

    def last_modified
      @response.headers[:last_modified]
    end

    def etag
      @response.headers[:etag]
    end

    def url
      result = @response.uri.to_s
      if @parsed_url.username && @parsed_url.password
        parts = result.split("/")
        parts[2] = credentials.to_s + parts[2]
        result = parts.join("/")
      end
      result
    end

    def credentials
      "#{@parsed_url.username}:#{@parsed_url.password}@"
    end

    def status
      @response.status
    end

    private

    def persisted_path
      @persisted_path ||= begin
        File.join(Dir.tmpdir, SecureRandom.hex)
      end
    end
  end
end
