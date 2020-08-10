# frozen_string_literal: true

module Feedkit
  class TwitterURLRecognizer
    attr_reader :screen_name, :type, :client_args
    attr_accessor :title

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
          query = CGI.parse(@url.query)
        end
        query["screen_name"] = @screen_name
        @url.query = URI.encode_www_form(query)
      end
      @url
    end

    def screen_name
      get_screen_name
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
        home unless valid?
        user unless valid?
        replies unless valid?
        search unless valid?
        list unless valid?
        hashtag unless valid?
        likes unless valid?
      end
    end

    def home
      return nil unless @url

      if host_valid? && ["", "/"].include?(@url.path)
        @valid = true
        @type = :twitter_home
        @title = "Twitter"
        @client_args = [:home_timeline, {count: 100, tweet_mode: "extended"}]
      end
    end

    def replies
      return nil unless @url

      paths = @url.path.split("/")
      user = nil
      id = nil

      if host_valid? && paths.length == 4 && paths[2] == "status"
        user = paths[1]
        id = paths[3].to_i
      end

      if user && id
        @valid = true

        query = "to:#{user} AND filter:replies"
        options = {
          since_id: id,
          result_type: "recent",
          include_entities: true,
          tweet_mode: "extended",
          count: 100
        }

        @title = "Replies to @#{user}"
        @client_args = [:search, query, options]
        @feed_options = {"twitter_user" => [:user, user]}

        @filters = [
          {
            proc: proc do |tweets, _|
              tweets.select { |tweet|
                tweet.in_reply_to_status_id? && tweet.in_reply_to_status_id == id
              }.reverse
            end
          }
        ]
      end
    end

    def user
      return nil unless @url

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
        @client_args = [:user_timeline, user, {count: 100, tweet_mode: "extended", exclude_replies: false}]
        @feed_options = {"twitter_user" => [:user, user]}

        if filter_replies
          @filters = [
            {
              proc: proc do |tweets, _|
                tweets.select { |tweet| tweet.retweet? || tweet.in_reply_to_screen_name.nil? || tweet.in_reply_to_screen_name == user }
                  .reject { |tweet| tweet.user_mentions.first&.indices&.first == 0 }
              end
            }
          ]
        end
      end
    end

    def search
      return nil unless @url
      return nil unless @url.query

      query = CGI.parse(@url.query)
      if host_valid? && @url.path == "/search" && query["q"]
        @valid = true

        query_string = query["q"].first
        options = {count: 100, tweet_mode: "extended", result_type: "recent", include_entities: true}
        unless query["l"].empty?
          options[:lang] = query["l"].first
        end
        @title = "Twitter Search: #{query_string}"
        @client_args = [:search, query_string, options]
      end
    end

    def hashtag
      return nil unless @url

      paths = @url.path.split("/")
      if host_valid? && paths.length == 3 && paths[1] == "hashtag"
        @valid = true

        query = "#" + paths.last
        @title = "Twitter: #{query}"
        @client_args = [:search, query, {count: 100, tweet_mode: "extended"}]
      end
    end

    def list
      return nil unless @url

      paths = @url.path.split("/")
      if host_valid? && paths.length == 4 && paths[2] == "lists"
        @valid = true

        user = paths[1]
        list = paths.last

        # send fake owner_id so the twitter gem doesn't mistakenly call verify_user
        if user == "i"
          list = list.to_i
          @client_args = [:list_timeline, list, {owner_id: 1, count: 100, tweet_mode: "extended"}]
          filter_args = [:list_members, list, {owner_id: 1, skip_status: true, include_entities: false, count: 5000}]
          @title = proc { |client|
            name = client.list(list, {owner_id: 1}).full_name
            "Twitter list: #{name}"
          }
        else
          @client_args = [:list_timeline, user, list, {count: 100, tweet_mode: "extended"}]
          @title = "Twitter List: #{user}/#{list}"
          filter_args = [:list_members, user, list, {skip_status: true, include_entities: false, count: 5000}]
        end

        @filters = [
          {
            args: filter_args,
            proc: proc do |tweets, members|
              valid_ids = members.map(&:id)
              tweets.select { |tweet| tweet.user && valid_ids.include?(tweet.user.id) }
            end
          }
        ]
      end
    end

    def likes
      return nil unless @url

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
        @client_args = [:favorites, user, {count: 100, tweet_mode: "extended"}]
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
      if hashtag = url.sub!(/^#/, "")
        url = "https://twitter.com/hashtag/#{hashtag}"
      elsif user = url.sub!(/^@/, "")
        url = "https://twitter.com/#{user}"
      end
      url
    end

    def get_screen_name
      if @screen_name
        @screen_name
      elsif @url.query
        query = CGI.parse(@url.query)
        query["screen_name"].first
      end
    end
  end
end
