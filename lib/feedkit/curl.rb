# frozen_string_literal: true

require "tempfile"
require "shellwords"
require "open3"
require "http"
require_relative "errors"

module Feedkit
  class Curl

    def self.download(url)
      new(url).download
    end

    def initialize(url)
      @parsed_url = BasicAuth.parse(url)
    end

    def download
      tempfile = Tempfile.new("request", binmode: true)
      params = {
        user_agent: ENV["FEEDKIT_USER_AGENT"] || "Feedbin",
        output: Shellwords.escape(tempfile.path),
        url: @parsed_url.url
      }
      command = "curl --location --silent --user-agent '%<user_agent>s' --output %<output>s '%<url>s'"
      out, _, status = Open3.capture3(command % params)
      if status.success?
        response = CurlResponse.new(@parsed_url.url)
        Response.new(tempfile: tempfile, response: response, parsed_url: @parsed_url, redirects: [])
      else
        raise ServerError.new(HTTP::Response::Status.new(500).to_s, nil)
      end
    end

    class CurlResponse
      def initialize(url)
        @url = url
        @status = status
      end

      def headers
        CurlHeaders.new
      end

      def uri
        @url
      end

      def content_type
        OpenStruct.new(charset: "UTF-8")
      end

      def status
        HTTP::Response::Status.new(200)
      end

      class CurlHeaders
        def get(header)
          []
        end
      end
    end

  end
end
