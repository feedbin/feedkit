# frozen_string_literal: true

require "digest"
require "base64"
require "http"
require_relative "errors"

module Feedkit
  class Request

    MAX_SIZE = 10 * 1024 * 1024

    # Sessions are immutable and thread-safe, so the parts of the client
    # that never change between requests are built once and shared
    CLIENT = HTTP
      .timeout(connect: 5, write: 5, read: 30)
      .encoding(Encoding::BINARY)

    AUTO_INFLATE_CLIENT = CLIENT.use(:auto_inflate)

    SSL_CONTEXT = OpenSSL::SSL::SSLContext.new.tap do |context|
      context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      context.setup # finalizes and freezes the context so it is safe to share
    end

    def self.download(url, **args)
      new(url, **args).download
    end

    def initialize(url, on_redirect: nil, auto_inflate: true, username: nil, password: nil, etag: nil, last_modified: nil, user_agent: nil, block_ssrf: false)
      @parsed_url    = BasicAuth.parse(url, username: username, password: password)
      @username      = @parsed_url.username
      @password      = @parsed_url.password
      @on_redirect   = on_redirect
      @auto_inflate  = auto_inflate
      @user_agent    = user_agent
      @last_modified = last_modified
      @etag          = etag
      @block_ssrf    = block_ssrf
      @redirects     = []
    end

    # curl resolves and connects on its own, so its addresses can't be checked
    # before it reaches them. FEEDKIT_CURL_HOSTS is an operator-curated list of
    # known-safe hosts rather than anything a feed can steer, so the shortcut
    # stays even when blocking SSRF: these hosts need curl to be fetched at all.
    def download
      if curl_host?
        return Curl.download(@parsed_url.url)
      end

      response = request
      if response.status.code == 304
        Response.new(tempfile: Tempfile.new, response: response, parsed_url: @parsed_url, redirects: @redirects)
      else
        download_to_file(response)
      end
    rescue => exception
      request_error!(exception)
    ensure
      response&.connection&.close
    end

    def download_to_file(response)
      tempfile = Tempfile.new("request", binmode: true)
      size = 0
      response.body.each do |chunk|
        tempfile.write(chunk)
        size += chunk.bytesize
        chunk.clear # deallocate string
        break if size > MAX_SIZE
      end
      tempfile.flush
      tempfile.rewind

      Response.new(tempfile: tempfile, response: response, parsed_url: @parsed_url, redirects: @redirects)
    rescue
      tempfile&.close
      raise
    end

    def client
      http = @auto_inflate ? AUTO_INFLATE_CLIENT : CLIENT
      http
        .headers(headers)
        .follow(max_hops: 4, on_redirect: on_redirect)
    end

    def headers
      Hash.new.tap do |hash|
        hash[:user_agent]        = @user_agent || "Feedbin"
        hash[:accept_encoding]   = "gzip, deflate"   if @auto_inflate
        hash[:if_none_match]     = @etag             unless @etag.nil?
        hash[:if_modified_since] = @last_modified    unless @last_modified.nil?
        hash[:authorization]     = basic_auth        unless basic_auth.nil?
      end
    end

    def basic_auth
      if @username && @password
        @basic_auth ||= "Basic " + Base64.strict_encode64("#{@username}:#{@password}")
      end
    end

    def on_redirect
      proc do |from, to|
        @redirects.push Redirect.new(status: from.status.code, from: from.uri.to_s, to: to.uri.to_s)
      end
    end

    def request
      response = client.get(@parsed_url.url, **request_options)
      response_error!(response) unless success?(response)
      response
    rescue => exception
      request_error!(exception)
    end

    def request_options
      options = {ssl_context: ssl_context}
      options[:socket_class] = PrivateAddressCheck::Socket if @block_ssrf
      options
    end

    def ssl_context
      SSL_CONTEXT
    end

    def success?(response)
      response.status.success? || response.code == 304
    end

    def response_error!(response)
      args = [response.status.to_s, response]

      case response.code
      when 401 then raise Unauthorized.new(*args)
      when 404 then raise NotFound.new(*args)
      when 400..499 then raise ClientError.new(*args)
      when 500..599 then raise ServerError.new(*args)
      else raise ResponseError.new(*args)
      end
    end

    def request_error!(exception)
      case exception
      when HTTP::RequestError, Addressable::URI::InvalidURIError, URI::InvalidURIError
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

    def url
      return @url if defined?(@url)
      @url = begin
        Addressable::URI.heuristic_parse(@parsed_url.url)
      rescue
        nil
      end
    end

    def curl_host?
      return @curl_host if defined?(@curl_host)
      @curl_host = host_in_list?(ENV["FEEDKIT_CURL_HOSTS"])
    end

    def accept_header_host?
      return @accept_header_host if defined?(@accept_header_host)
      @accept_header_host = host_in_list?(ENV["FEEDKIT_ACCEPT_HOSTS"])
    end

    def host_in_list?(list)
      return false if list.nil?
      url.respond_to?(:host) && list.split(",").include?(url.host)
    end
  end
end
