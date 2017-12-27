require 'feedjira'
require 'twitter'
require 'twitter-text'
require 'curb'
require 'socket'
require 'cgi'

require "feedbin/feedjira_extension"

require "feedbin/parser/feed_request"
require "feedbin/parser/twitter_url_recognizer"
require "feedbin/parser/twitter_feed"

require "feedbin/parser/parsed_entry"
require "feedbin/parser/parsed_feed"
require "feedbin/parser/parsed_json_entry"
require "feedbin/parser/parsed_json_feed"
require "feedbin/parser/parsed_tweet_entry"
require "feedbin/parser/parsed_twitter_feed"
require "feedbin/parser/parsed_xml_entry"
require "feedbin/parser/parsed_xml_feed"
require "feedbin/parser/version"

module Feedbin
  module Parser
    def self.fetch_and_parse(url, options: {})
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
        feed = TwitterFeed.new(twitter_url, options[:twitter_token], options[:twitter_secret]).feed
      end
      feed
    end

    def self.request_feed(url, options)
      feed = nil
      request = options[:request]
      if request.nil?
        request = FeedRequest.new(url: url)
      end
      if !request.body.nil? && [:xml, :json_feed].include?(request.format)
        if request.format == :xml
          feed = ParsedXMLFeed.new(request.body, request)
        elsif request.format == :json_feed
          feed = ParsedJSONFeed.new(request.body, request)
        end
      end
      feed
    end

  end
end
