source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "sax-machine", github: "feedbin/sax-machine", branch: "feedbin"
gem "feedjira",    path: "/Users/ben/Sites/feedj/feedjira_two"
gem "http",        github: "feedbin/http",        branch: "feedbin"
gem "twitter",     github: "feedbin/twitter",     branch: "feedbin"

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
