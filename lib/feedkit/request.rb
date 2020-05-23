# frozen_string_literal: true
require "digest"
require "http"
require_relative "errors"

module Feedkit
  class Request

    attr_reader :url, :client, :options

    def initialize(url:, options: {})
      puts url.inspect
      @url = url
      @options = options
      @client = HTTP
        .headers(HTTP::Headers::ACCEPT_ENCODING => "gzip")
        .headers(HTTP::Headers::USER_AGENT => user_agent)
        .use(:auto_inflate)
        .follow(max_hops: 5)
        .timeout(connect: 5, write: 5, read: 20)
    end

    def self.download(**keyword_args)
      new(**keyword_args).download
    end

    def download
      response = client.get(url)

      if max_size && response.content_length && response.content_length > max_size
        raise TooLarge, "file is too large (max is #{max_size/1024}KB)"
      end

      tempfile = Tempfile.new(["feedkit-request"], binmode: true)
      response.body.each do |chunk|
        tempfile.write(chunk)
        if !valid?(chunk)
          raise NotFeed, "file does not appear to be a feed"
        end
        if max_size && tempfile.size > max_size
          raise TooLarge, "file is too large (max is #{max_size/1024}KB)"
        end
      end

      FileUtils.mv tempfile.path, download_file_path
      download_file_path
    end

    def valid?(chunk)
      if @valid.nil?
        @valid = xml_feed?(chunk)
        # TODO implement json_feed?
        # @valid = json_feed?(chunk) if !@valid
      else
        @valid
      end
    end

    def xml_feed?(chunk)
      feed_found = false
      Nokogiri::XML::Reader(chunk).each do |node|
        if !feed_found && ["channel", "feed"].include?(node.name)
          feed_found = true
        end
      end
      feed_found
    rescue
      feed_found
    end

    def user_agent
      options.fetch(:user_agent, "Feedbin")
    end

    def download_file_path
      File.join(Dir.tmpdir, download_file_name)
    end

    def download_file_name
      @download_file_name ||= begin
        Digest::SHA1.hexdigest([url, username, password].join(":"))
      end
    end

    def username
      options[:username]
    end

    def password
      options[:password]
    end

    def max_size
      options.fetch(:max_size, 10 * 1024 * 1024)
    end

  end
end


