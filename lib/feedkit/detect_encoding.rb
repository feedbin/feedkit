# frozen_string_literal: true

module Feedkit
  class DetectEncoding
    def initialize(string)
      @string = string
    end

    def self.detect(string)
      new(string).detect
    end

    def detect
      @result = CharDet.detect(@string.slice(0, 250_000))
      self
    end

    def encoding
      @result && @result["encoding"]
    end

    def confidence
      @result ? @result["confidence"] : 0.0
    end

    def confident?
      confidence > 0.85
    end
  end
end
