require 'feedjira'
require 'twitter'
require 'twitter-text'
require 'curb'
require 'socket'
require 'cgi'

require "feedkit/feedjira_extension"

require "feedkit/version"
require "feedkit/request"
require "feedkit/twitter_url_recognizer"
require "feedkit/tweets"

require "feedkit/parser/entry"
require "feedkit/parser/feed"
require "feedkit/parser/json_entry"
require "feedkit/parser/json_feed"
require "feedkit/parser/twitter_entry"
require "feedkit/parser/twitter_feed"
require "feedkit/parser/xml_entry"
require "feedkit/parser/xml_feed"

module Feedkit
  def self.fetch_and_parse(url, options = {})
    feed = nil
    feed = twitter_feed(url, options) if feed.nil?
    feed = request_feed(url, options) if feed.nil?
    feed
  end

  private

  def self.twitter_feed(url, options)
    feed = nil
    twitter_url = TwitterURLRecognizer.new(url, options[:twitter_screen_name])
    if twitter_url.valid?
      feed = Tweets.new(twitter_url, options[:twitter_access_token], options[:twitter_access_secret]).feed
    end
    feed
  end

  def self.request_feed(url, options)
    feed = nil
    request = options[:request]
    if request.nil?
      request = Request.new(url: url)
    end
    if !request.body.nil? && [:xml, :json_feed].include?(request.format)
      if request.format == :xml
        feed = Parser::XMLFeed.new(request.body, request)
      elsif request.format == :json_feed
        feed = Parser::JSONFeed.new(request.body, request)
      end
    end
    feed
  end

end
