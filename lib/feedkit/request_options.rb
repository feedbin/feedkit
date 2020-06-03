# frozen_string_literal: true

require "digest"
require "http"
require_relative "errors"

module Feedkit
  class RequestOptions
    attr_reader :user_agent, :username, :password

    def initialize(etag: nil, last_modified: nil, user_agent: "Feedbin", username: nil, password: nil)
      @etag = etag
      @last_modified = last_modified
      @user_agent = user_agent
      @username = username
      @password = password
    end

    def if_none_match
      {if_none_match: @etag} unless @etag.nil?
    end

    def if_modified_since
      {if_modified_since: @last_modified} unless @last_modified.nil?
    end
  end
end
