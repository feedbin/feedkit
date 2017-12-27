require 'feedjira'
require 'twitter'
require 'twitter-text'
require 'curb'
require 'socket'
require 'cgi'

require "feedkit/feedjira_extension"

require "feedkit/parser/feed_request"
require "feedkit/parser/twitter_url_recognizer"
require "feedkit/parser/twitter_feed"

require "feedkit/parser/parsed_entry"
require "feedkit/parser/parsed_feed"
require "feedkit/parser/parsed_json_entry"
require "feedkit/parser/parsed_json_feed"
require "feedkit/parser/parsed_tweet_entry"
require "feedkit/parser/parsed_twitter_feed"
require "feedkit/parser/parsed_xml_entry"
require "feedkit/parser/parsed_xml_feed"
require "feedkit/version"

module Feedkit
  def self.fetch_and_parse(url, options: {})
    feed = nil
    feed = twitter_feed(url, options) if feed.nil?
    feed = request_feed(url, options) if feed.nil?
    feed
  end

  private

  def self.twitter_feed(url, options)
    feed = nil
    twitter_url = Parser::TwitterURLRecognizer.new(url, options[:twitter_screen_name])
    if twitter_url.valid?
      feed = Parser::TwitterFeed.new(twitter_url, options[:twitter_token], options[:twitter_secret]).feed
    end
    feed
  end

  def self.request_feed(url, options)
    feed = nil
    request = options[:request]
    if request.nil?
      request = Parser::FeedRequest.new(url: url)
    end
    if !request.body.nil? && [:xml, :json_feed].include?(request.format)
      if request.format == :xml
        feed = Parser::ParsedXMLFeed.new(request.body, request)
      elsif request.format == :json_feed
        feed = Parser::ParsedJSONFeed.new(request.body, request)
      end
    end
    feed
  end

end
