# frozen_string_literal: true

require "digest"
require "http"
require_relative "errors"

module Feedkit
  class Request

    MAX_SIZE = 10 * 1024 * 1024

    def self.download(url, **args)
      new(url, **args).download
    end

    def initialize(url, on_redirect: nil, etag: nil, last_modified: nil, user_agent: "Feedbin")
      @parsed_url    = BasicAuth.parse(url)
      @on_redirect   = on_redirect
      @user_agent    = user_agent
      @last_modified = last_modified
      @etag          = etag
      @username      = @parsed_url.username
      @password      = @parsed_url.password
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

      Response.new(tempfile: tempfile, response: response, parsed_url: @parsed_url)
    rescue => exception
      tempfile&.close
      request_error!(exception)
    ensure
      response&.connection&.close
    end

    def client
      HTTP
       .headers(headers)
       .follow(max_hops: 4, on_redirect: @on_redirect)
       .timeout(connect: 5, write: 5, read: 15)
       .encoding(Encoding::BINARY)
       .use(:auto_inflate)
    end

    def headers
      Hash.new.tap do |hash|
        hash[:accept_encoding]   = "gzip, deflate"
        hash[:user_agent]        = @user_agent

        hash[:if_none_match]     = @etag          unless @etag.nil?
        hash[:if_modified_since] = @last_modified unless @last_modified.nil?
        hash[:authorization]     = basic_auth     unless basic_auth.nil?
      end
    end

    def basic_auth
      if @username && @password
        @basic_auth ||= "Basic " + Base64.strict_encode64("#{@username}:#{@password}")
      end
    end

    def request
      response = client.get(@parsed_url.url)
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
      when HTTP::StateError
        raise StateError, exception.message
      when HTTP::Redirector::TooManyRedirectsError
        raise TooManyRedirects, exception.message
      when OpenSSL::SSL::SSLError
        raise SSLError, exception.message
      when Zlib::BufError, Zlib::DataError
        raise ZlibError, exception.message
      else
        raise exception
      end
    end
  end
end
