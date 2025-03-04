module Feedkit
  class Redirect
    PERMANENT_REDIRECTS = [301, 308].to_set.freeze

    attr_reader :status, :from, :to

    def initialize(status:, from:, to:)
      @status = status
      @from = from
      @to = to
    end

    def permanent?
      PERMANENT_REDIRECTS.include?(@status)
    end
  end
end