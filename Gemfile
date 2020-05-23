source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'feedjira', github: 'feedbin/feedjira', ref: 'e6b7b11'
gem 'http', github: 'feedbin/http', branch: 'redirect_callback'

group :development do
  gem "dotenv"
end

# Specify your gem's dependencies in feedkit.gemspec
gemspec
