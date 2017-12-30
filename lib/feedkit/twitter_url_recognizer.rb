module Feedkit
  class TwitterURLRecognizer
    attr_reader :url

    def initialize(url, screen_name)
      @url = format_url(url)
      @screen_name = screen_name
      recognize
    end

    def type
      @type
    end

    def value
      @value
    end

    def valid?
      !!(type && value)
    end

    private

    def recognize
      @recognize ||= begin
        home if !valid?
        user if !valid?
        search if !valid?
        list if !valid?
        hashtag if !valid?
      end
    end

    def home
      return nil if !@url

      if @url.host == "twitter.com" && ["", "/"].include?(@url.path)
        if @url.query
          query = CGI::parse(@url.query)
          @screen_name = query["screen_name"].first
        end
        @value = @screen_name
        @type = :home
      end
    end

    def user
      return nil if !@url

      paths = @url.path.split("/")
      if @url.host == "twitter.com" && paths.length == 2 && @url.path != "/search"
        @value = paths.last
        @type = :user
      end
    end

    def search
      return nil if !@url
      return nil if !@url.query

      query = CGI::parse(@url.query)
      if @url.host == "twitter.com" && @url.path == "/search" && query["q"]
        @value = {query: query["q"].first}
        if !query["l"].empty?
          @value[:lang] = query["l"].first
        end
        @type = :search
      end
    end

    def list
      return nil if !@url

      paths = @url.path.split("/")
      if @url.host == "twitter.com" && paths.length == 4 && paths[2] == "lists"
        @value = {user: paths[1], list: paths.last}
        @type = :list
      end
    end

    def hashtag
      return nil if !@url

      paths = @url.path.split("/")
      if @url.host == "twitter.com" && paths.length == 3 && paths[1] == "hashtag"
        @value = {query: '#' + paths.last}
        @type = :search
      end
    end

    def format_url(url)
      url = url.strip
      url = shortcut(url)
      if url.start_with?("twitter.com")
        url = "https://#{url}"
      end
      URI.parse(url)
    rescue
      nil
    end

    def shortcut(url)
      if hashtag = url.sub!(/^#/, '')
        url = "https://twitter.com/hashtag/#{hashtag}"
      elsif user = url.sub!(/^@/, '')
        url = "https://twitter.com/#{user}"
      end
      url
    end

  end
end
