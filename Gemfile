source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "sax-machine", github: "feedbin/sax-machine", branch: "feedbin"
gem "feedjira",    github: "feedbin/feedjira",    branch: "f2"
gem "http",        github: "feedbin/http",        branch: "feedbin"
gem "twitter",     github: "feedbin/twitter",     branch: "feedbin"

group :development do
  gem "dotenv"
end

# Specify your gem's dependencies in feedkit.gemspec
gemspec
