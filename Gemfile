source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "sax-machine", github: "feedbin/sax-machine", branch: "feedbin"
gem "feedjira",    github: "feedbin/feedjira",    branch: "f2"

group :development do
  gem "dotenv"
  gem "sinatra"
  gem "webrick"
  gem "better_errors"
  gem "binding_of_caller"
  gem "rerun"
end

# Specify your gem's dependencies in feedkit.gemspec
gemspec
