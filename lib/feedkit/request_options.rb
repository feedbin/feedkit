# frozen_string_literal: true

require "digest"
require "http"
require_relative "errors"

module Feedkit
  class RequestOptions

    attr_reader :user_agent, :username, :password

    def initialize(etag: nil, last_modified: nil, user_agent: "Feedbin", username: nil, password: nil)
      @etag          = etag
      @last_modified = last_modified
      @user_agent    = user_agent
      @username      = username
      @password      = password
    end

    def if_none_match
      {if_none_match: @etag} unless @etag.nil?
    end

    def if_modified_since
      unless @last_modified.respond_to?(:httpdate)
        @last_modified = Time.parse(@last_modified)
      end
      {if_modified_since: @last_modified.httpdate}
    rescue
      nil
    end

  end
end


