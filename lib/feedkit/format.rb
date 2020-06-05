# frozen_string_literal: true

require "digest"
require "http"
require_relative "errors"

module Feedkit
  class Format
    attr_reader :data, :encoding

    def initialize(data, charset)
      @data = data
      @charset = charset
    end

    def valid?; end


  end
end
