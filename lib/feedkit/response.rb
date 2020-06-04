# frozen_string_literal: true

require "digest"

module Feedkit
  class Response
    attr_reader :path, :file_format

    def initialize(path:, http:, file_format:)
      @path = path
      @http = http
      @file_format = file_format
    end

    def body
      @body ||= File.read(@path)
    end

    def parse
      @parse ||= Parser.parse!(@file_format, body, url)
    end

    def persist!
      FileUtils.mv @path, persisted_path
      @path = persisted_path
    end

    def persisted_path
      @persisted_path ||= begin
        File.join(Dir.tmpdir, SecureRandom.hex)
      end
    end

    def checksum
      Digest::SHA1.hexdigest(body)[0..6]
    end

    def url
      @http.uri.to_s
    end

    def last_modified
      @http.headers[:last_modified]
    end

    def etag
      @http.headers[:etag]
    end

    def status
      @http.status
    end

    def charset
      @http.content_type.charset.downcase
    end

    def xml?
      file_format == "xml"
    end

    def json?
      file_format == "json"
    end

    def html?
      file_format == "html"
    end
  end
end
