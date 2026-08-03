# frozen_string_literal: true

module Feedkit
  class DetectEncoding

    MAX_SAMPLE = 250_000

    def initialize(string)
      @string = string
    end

    def self.detect(string)
      new(string).detect
    end

    def detect
      @result = CharDet.detect(sample)
      self
    end

    # A body at or under the limit is its own sample. Slicing it would copy the
    # whole string to produce an equal one, and bodies are usually well under.
    def sample
      return @string if @string.bytesize <= MAX_SAMPLE
      @string.slice(0, MAX_SAMPLE)
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
