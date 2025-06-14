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

    def initialize(url, on_redirect: nil, auto_inflate: true, username: nil, password: nil, etag: nil, last_modified: nil, user_agent: nil)
      @parsed_url    = BasicAuth.parse(url, username: username, password: password)
      @url           = Addressable::URI.heuristic_parse(@parsed_url.url) rescue nil
      @username      = @parsed_url.username
      @password      = @parsed_url.password
      @on_redirect   = on_redirect
      @auto_inflate  = auto_inflate
      @user_agent    = user_agent
      @last_modified = last_modified
      @etag          = etag
      @redirects     = []
    end

    def download
      if curl_host?
        return Curl.download(@parsed_url.url)
      end

      response = request
      if response.status.code == 304
        Response.new(tempfile: Tempfile.new, response: response, parsed_url: @parsed_url, redirects: @redirects, proxied: proxy_host?)
      else
        download_to_file(response)
      end
    rescue OpenSSL::SSL::SSLError => exception
      # HTTP sometimes has this error that doesn't show up in other clients
      if exception.message.include?("unexpected eof while reading")
        return Curl.download(@parsed_url.url)
      else
        raise exception
      end
    rescue => exception
      request_error!(exception)
    ensure
      response&.connection&.close
    end

    def download_to_file(response)
      tempfile = Tempfile.new("request", binmode: true)
      response.body.each do |chunk|
        tempfile.write(chunk)
        chunk.clear # deallocate string
        break if tempfile.size > MAX_SIZE
      end
      tempfile.open # flush written content
      tempfile.rewind

      Response.new(tempfile: tempfile, response: response, parsed_url: @parsed_url, redirects: @redirects, proxied: proxy_host?)
    rescue
      tempfile&.close
      raise
    end

    def client
      http = HTTP
       .headers(headers)
       .follow(max_hops: 4, on_redirect: on_redirect)
       .timeout(connect: 5, write: 5, read: 30)
       .encoding(Encoding::BINARY)

      http = http.use(:auto_inflate) if @auto_inflate

      http
    end

    def headers
      Hash.new.tap do |hash|
        hash[:user_agent]        = @user_agent || "Feedbin"
        hash[:accept_encoding]   = "gzip, deflate"   if @auto_inflate
        hash[:x_proxy_host]      = @url.host         if proxy_host?
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
      url = proxy_host? ? proxied_url : @parsed_url.url
      response = client.get(url, ssl_context: ssl_context)
      response_error!(response) unless success?(response)
      response
    rescue => exception
      request_error!(exception)
    end

    def ssl_context
      options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] | OpenSSL::SSL::OP_LEGACY_SERVER_CONNECT
      OpenSSL::SSL::SSLContext.new.tap do |context|
        context.set_params(options: options)
      end
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

    def proxied_url
      Feedkit::Rebase.call(target: @url, base: ENV["FEEDKIT_PROXY_HOST"]).to_s
    end

    def proxy_host?
      hosts = ENV["FEEDKIT_PROXIED_HOSTS"]&.split(",") || []
      @url.respond_to?(:host) && hosts.include?(@url.host)
    end

    def curl_host?
      hosts = ENV["FEEDKIT_CURL_HOSTS"]&.split(",") || []
      @url.respond_to?(:host) && hosts.include?(@url.host)
    end

    def accept_header_host?
      hosts = ENV["FEEDKIT_ACCEPT_HOSTS"]&.split(",") || []
      @url.respond_to?(:host) && hosts.include?(@url.host)
    end
  end
end
