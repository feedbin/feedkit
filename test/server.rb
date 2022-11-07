$LOAD_PATH.unshift File.expand_path("./lib", __dir__)

require "json"
require "feedkit"
require 'sinatra'
require "better_errors"

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

get '/' do
end
