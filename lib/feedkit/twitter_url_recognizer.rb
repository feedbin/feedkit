module Feedkit
  class TwitterURLRecognizer
    attr_reader :url

    DEFAULT_OPTIONS = {
      count: 100,
      tweet_mode: "extended"
    }

    def initialize(url, screen_name)
      @url = format_url(url)
      @screen_name = screen_name
      @client_args = []
      @valid = false
      @type = :twitter
      recognize
    end

    def type
      @type
    end

    def title
      @title
    end

    def client_args
      @client_args
    end

    def feed_options
      @feed_options || {}
    end

    def valid?
      @valid
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
        @valid = true
        if @url.query
          query = CGI::parse(@url.query)
          @screen_name = query["screen_name"].first
        end
        @type = :twitter_home
        @title = "Twitter"
        @client_args = [:home_timeline, DEFAULT_OPTIONS]
        @url.query = "screen_name=#{@screen_name}"
      end
    end

    def user
      return nil if !@url

      paths = @url.path.split("/")
      if @url.host == "twitter.com" && paths.length == 2 && @url.path != "/search"
        @valid = true

        user = paths.last
        @title = "@#{user}"
        @client_args = [:user_timeline, user, DEFAULT_OPTIONS.merge(exclude_replies: true)]
        @feed_options = { "twitter_user" => [:user, user] }
      end
    end

    def search
      return nil if !@url
      return nil if !@url.query

      query = CGI::parse(@url.query)
      if @url.host == "twitter.com" && @url.path == "/search" && query["q"]
        @valid = true

        query_string = query["q"].first
        options = DEFAULT_OPTIONS.merge(result_type: "recent", include_entities: true)
        if !query["l"].empty?
          options[:lang] = query["l"].first
        end
        @title = "Twitter Search: #{query_string}"
        @client_args = [:search, CGI.escape(query_string), options]
      end
    end

    def hashtag
      return nil if !@url

      paths = @url.path.split("/")
      if @url.host == "twitter.com" && paths.length == 3 && paths[1] == "hashtag"
        @valid = true

        query = '#' + paths.last
        @title = "Twitter: #{query}"
        @client_args = [:search, query, DEFAULT_OPTIONS]
      end
    end

    def list
      return nil if !@url

      paths = @url.path.split("/")
      if @url.host == "twitter.com" && paths.length == 4 && paths[2] == "lists"
        @valid = true

        user = paths[1]
        list = paths.last

        @title = "Twitter List: #{user}/#{list}"
        @client_args = [:list_timeline, user, list, DEFAULT_OPTIONS]
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
