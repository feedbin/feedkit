module Feedkit
  class TwitterURLRecognizer
    attr_reader :screen_name

    def initialize(url, screen_name)
      @url = format_url(url)
      @screen_name = screen_name
      @client_args = []
      @valid = false
      @type = :twitter
      recognize
    end

    def url
      if @screen_name
        query = {}
        if @url.query
          query = CGI::parse(@url.query)
        end
        query["screen_name"] = @screen_name
        @url.query = URI.encode_www_form(query)
      end
      @url
    end

    def screen_name
      get_screen_name
    end

    def type
      @type
    end

    def title=(title)
      @title = title
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
        likes if !valid?
      end
    end

    def home
      return nil if !@url

      if host_valid? && ["", "/"].include?(@url.path)
        @valid = true
        @type = :twitter_home
        @title = "Twitter"
        @client_args = [:home_timeline, { count: 100, tweet_mode: "extended" }]
      end
    end

    def user
      return nil if !@url

      paths = @url.path.split("/")
      user = nil

      if host_valid? && paths.length == 2 && @url.path != "/search"
        user = paths.last
        filter_replies = true
      elsif host_valid? && paths.length == 3 && paths.last == "with_replies"
        user = paths[1]
        filter_replies = false
      end

      if user
        @valid = true

        @title = "@#{user}"
        @client_args = [:user_timeline, user, { count: 100, tweet_mode: "extended", exclude_replies: false}]
        @feed_options = { "twitter_user" => [:user, user] }

        if filter_replies
          @filters = [
            {
              proc: Proc.new do |tweets, _|
                tweets.select {|tweet| tweet.retweet? || tweet.in_reply_to_screen_name.nil? || tweet.in_reply_to_screen_name == user }
                  .reject {|tweet| tweet.user_mentions.first&.indices&.first == 0 }
              end
            }
          ]
        end
      end
    end

    def search
      return nil if !@url
      return nil if !@url.query

      query = CGI::parse(@url.query)
      if host_valid? && @url.path == "/search" && query["q"]
        @valid = true

        query_string = query["q"].first
        options = { count: 100, tweet_mode: "extended", result_type: "recent", include_entities: true}
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
        @client_args = [:search, query, { count: 100, tweet_mode: "extended" }]
      end
    end

    def list
      return nil if !@url

      paths = @url.path.split("/")
      if host_valid? && paths.length == 4 && paths[2] == "lists"
        @valid = true

        user = paths[1]
        list = paths.last

        if user == "i"
          list = list.to_i
          @client_args = [:list_timeline, list, { count: 100, tweet_mode: "extended" }]
          filter_args = [:list_members, list, {skip_status: true, include_entities: false, count: 5000}]
          @title = Proc.new do |client|
            "Twitter list: #{client.list(list).full_name}"
          end
        else
          @client_args = [:list_timeline, user, list, { count: 100, tweet_mode: "extended" }]
          @title = "Twitter List: #{user}/#{list}"
          filter_args = [:list_members, user, list, {skip_status: true, include_entities: false, count: 5000}]
        end

        @filters = [
          {
            args: filter_args,
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
        user = get_screen_name
      elsif host_valid? && paths.length == 3 && paths.last == "likes"
        user = paths[1]
      end

      if user
        @valid = true
        @title = "@#{user} Likes"
        @client_args = [:favorites, user, { count: 100, tweet_mode: "extended" }]
      end
    end

    def host_valid?
      @url && ["twitter.com"].include?(@url.host)
    end

    def format_url(url)
      url = url.strip
      url = shortcut(url)
      if url.start_with?("twitter.com")
        url = "https://#{url}"
      elsif url.start_with?("mobile.twitter.com")
        url = "https://#{url}"
      end

      url = URI.parse(url)

      if ["twitter.com", "mobile.twitter.com"].include?(url.host)
        url.host = "twitter.com"
      end

      url
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
      if @screen_name
        @screen_name
      elsif @url.query
        query = CGI::parse(@url.query)
        query["screen_name"].first
      end
    end

  end
end
