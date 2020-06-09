# frozen_string_literal: true

require "digest"

module Feedkit
  class Response
    attr_reader :path

    def initialize(tempfile:, response:)
      @tempfile = tempfile
      @path = tempfile.path
      @response = response
    end

    def body
      @body ||= File.read(@path, binmode: true)
    end

    def parse(validate: true)
      @parse ||= Parser.parse!(body, url: url, validate: validate)
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

    def url
      @response.uri.to_s
    end

    def last_modified
      @response.headers[:last_modified]
    end

    def etag
      @response.headers[:etag]
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
