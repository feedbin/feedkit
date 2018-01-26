module Feedkit
  class TwitterURLRecognizer
    attr_reader :url, :screen_name

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

    def filters
      @filters || []
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
        # likes if !valid?
      end
    end

    def home
      return nil if !@url


      if host_valid? && ["", "/"].include?(@url.path) && screen_names_match?
        @screen_name = get_screen_name
        @valid = true
        @type = :twitter_home
        @title = "Twitter"
        @client_args = [:home_timeline, DEFAULT_OPTIONS]
        @url.query = "screen_name=#{@screen_name}"
      end
    end

    def user
      return nil if !@url

      paths = @url.path.split("/")
      user = nil

      if host_valid? && paths.length == 2 && @url.path != "/search"
        user = paths.last
        exclude_replies = true
      elsif host_valid? && paths.length == 3 && paths.last == "with_replies"
        user = paths[1]
        exclude_replies = false
      end

      if user
        @valid = true

        @title = "@#{user}"
        @client_args = [:user_timeline, user, DEFAULT_OPTIONS.merge(exclude_replies: exclude_replies)]
        @feed_options = { "twitter_user" => [:user, user] }
      end
    end

    def search
      return nil if !@url
      return nil if !@url.query

      query = CGI::parse(@url.query)
      if host_valid? && @url.path == "/search" && query["q"]
        @valid = true

        query_string = query["q"].first
        options = DEFAULT_OPTIONS.merge(result_type: "recent", include_entities: true)
        if !query["l"].empty?
          options[:lang] = query["l"].first
        end
        @title = "Twitter Search: #{query_string}"
        @client_args = [:search, query_string, options]
      end
    end

    def hashtag
      return nil if !@url

      paths = @url.path.split("/")
      if host_valid? && paths.length == 3 && paths[1] == "hashtag"
        @valid = true

        query = '#' + paths.last
        @title = "Twitter: #{query}"
        @client_args = [:search, query, DEFAULT_OPTIONS]
      end
    end

    def list
      return nil if !@url

      paths = @url.path.split("/")
      if host_valid? && paths.length == 4 && paths[2] == "lists"
        @valid = true

        user = paths[1]
        list = paths.last

        @title = "Twitter List: #{user}/#{list}"
        @client_args = [:list_timeline, user, list, DEFAULT_OPTIONS]
        @filters = [
          {
            args: [:list_members, user, list, {skip_status: true, include_entities: false, count: 5000}],
            proc: Proc.new do |tweets, members|
              valid_ids = members.map(&:id)
              tweets.select {|tweet| tweet.user && valid_ids.include?(tweet.user.id) }
            end
          }
        ]
      end
    end

    def likes
      return nil if !@url

      paths = @url.path.split("/")
      user = nil

      if host_valid? && paths.length == 3 && paths.join("/") == "/i/likes"
        if screen_names_match?
          @url.query = "screen_name=#{get_screen_name}"
          @type = :twitter_home
          user = @screen_name
        end
      elsif host_valid? && paths.length == 3 && paths.last == "likes"
        user = paths[1]
      end

      if user
        @valid = true
        @title = "@#{user} Likes"
        @client_args = [:favorites, user, DEFAULT_OPTIONS]
      end
    end

    def host_valid?
      @url && ["twitter.com", "mobile.twitter.com"].include?(@url.host)
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

    def get_screen_name
      if @url.query
        query = CGI::parse(@url.query)
        screen_name = query["screen_name"].first
      else
        screen_name = @screen_name
      end
    end

    def screen_names_match?
      if @url.query
        query = CGI::parse(@url.query)
        url_screen_name = query["screen_name"].first
      end

      screen_names_match = true
      if @screen_name && url_screen_name
        screen_names_match = (url_screen_name == @screen_name)
      end

      screen_names_match
    end

  end
end
