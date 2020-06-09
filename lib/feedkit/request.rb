# frozen_string_literal: true

require "digest"
require "http"
require_relative "errors"

module Feedkit
  class Request
    attr_reader :url, :client, :options

    MAX_SIZE = 10 * 1024 * 1024

    def self.download(url, **args)
      new(url, **args).download
    end

    def initialize(url, on_redirect: nil, options: RequestOptions.new)
      @url = url
      @options = options
      @client = HTTP
        .use(:auto_inflate)
        .headers(accept_encoding: "gzip")
        .headers(user_agent: options.user_agent)
        .timeout(connect: 5, write: 5, read: 5)
        .follow(max_hops: 4, on_redirect: on_redirect)
        .encoding(Encoding::BINARY)

      if options.username && options.password
        @client = @client.basic_auth(user: options.username, pass: options.password)
      end
      if options.if_none_match
        @client = @client.headers(options.if_none_match)
      end
      if options.if_modified_since
        @client = @client.headers(options.if_modified_since)
      end
    end

    def download
      response = request

      if response.content_length && response.content_length > MAX_SIZE
        raise TooLarge, "file is too large (max is #{MAX_SIZE / 1024}KB)"
      end

      tempfile = Tempfile.new("request", binmode: true)
      response.body.each do |chunk|
        tempfile.write(chunk)
        chunk.clear # deallocate string
        if tempfile.size > MAX_SIZE
          raise TooLarge, "file is too large (max is #{MAX_SIZE / 1024}KB)"
        end
      end
      tempfile.open # flush written content
      tempfile.rewind

      Response.new(tempfile: tempfile, response: response)
    rescue
      tempfile&.close
      raise
    ensure
      response&.connection&.close
    end

    def request
      response = client.get(url)
      response_error!(response) unless response.status.success?
      response
    rescue => exception
      request_error!(exception)
    end

    def response_error!(response)
      args = [response.status.to_s, response]

      case response.code
      when 304 then raise NotModified.new(*args)
      when 401 then raise Unauthorized.new(*args)
      when 404 then raise NotFound.new(*args)
      when 400..499 then raise ClientError.new(*args)
      when 500..599 then raise ServerError.new(*args)
      else raise ResponseError.new(*args)
      end
    end

    def request_error!(exception)
      case exception
      when HTTP::Request::UnsupportedSchemeError, Addressable::URI::InvalidURIError
        raise InvalidUrl, exception.message
      when HTTP::ConnectionError
        raise ConnectionError, exception.message
      when HTTP::TimeoutError
        raise TimeoutError, exception.message
      when HTTP::Redirector::TooManyRedirectsError
        raise TooManyRedirects, exception.message
      when OpenSSL::SSL::SSLError
        raise SSLError, exception.message
      else
        raise exception
      end
    end
  end
end
