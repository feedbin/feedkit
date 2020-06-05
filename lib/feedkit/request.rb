# frozen_string_literal: true

require "digest"
require "http"
require_relative "errors"

module Feedkit
  class Request
    attr_reader :url, :client, :options

    FEED_FORMATS = {xml: "xml", json: "json"}

    SUPPORTED_FORMATS = FEED_FORMATS.merge(html: "html")

    MAX_SIZE = 10 * 1024 * 1024

    def initialize(url, validate: true, on_redirect: nil, options: RequestOptions.new)
      @url = url
      @validate = validate
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

    def self.download(url, **args)
      new(url, **args).download
    end

    def download
      response = request

      if response.content_length && response.content_length > MAX_SIZE
        raise TooLarge, "file is too large (max is #{MAX_SIZE / 1024}KB)"
      end

      tempfile = Tempfile.new("request", binmode: true)

      response.body.each do |chunk|
        tempfile.write(chunk)
        if tempfile.size > MAX_SIZE
          raise TooLarge, "file is too large (max is #{MAX_SIZE / 1024}KB)"
        end
      end

      tempfile.rewind

      file_format = determine_format(tempfile.read.lstrip)
      if validate? && !FEED_FORMATS.values.include?(file_format)
        raise NotFeed, "result is not a feed"
      end

      tempfile.close

      Response.new(path: tempfile.path, http: response, file_format: file_format)
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

    def determine_format(data)
      result = nil
      if !result && xml?(data)
        result = SUPPORTED_FORMATS[:xml]
      end
      if !result && json?(data)
        result = SUPPORTED_FORMATS[:json]
      end
      if !result && html?(data)
        result = SUPPORTED_FORMATS[:html]
      end
      result
    end

    def xml?(data)
      found = false
      xml_reader(data, encoding: nil)
      found
    rescue Nokogiri::XML::SyntaxError => e
      puts e.code
      puts e.domain
      puts e.to_s
      raise
    end

    def html?(data)
      Nokogiri::HTML.fragment(data).css("link, meta, a").length > 0
    rescue
      false
    end

    def json?(data)
      JSON.load(data)["version"].include?("https://jsonfeed.org/version/")
    rescue
      false
    end

    def validate?
      @validate
    end

    def xml_reader(data, encoding: nil)
      args = [data, nil]
      args.push(encoding) unless encoding.nil?
      Nokogiri::XML::Reader(*args).each do |node|
        if !found && ["rss", "atom", "channel", "feed"].include?(node.name)
          found = true
        end
      end
    end
  end
end
