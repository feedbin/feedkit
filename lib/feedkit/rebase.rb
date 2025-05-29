module Feedkit
  class Rebase

    def initialize(target:, base:)
      @target = target
      @base = base
    end

    def self.call(...)
      new(...).call
    end

    def call
      parsed_base = Addressable::URI.heuristic_parse(@base)
      Addressable::URI.heuristic_parse(@target).tap do |uri|        
        uri.scheme = parsed_base.scheme
        uri.host   = parsed_base.host
      end
    end
  end
end
