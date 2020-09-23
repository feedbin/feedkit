lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "feedkit/version"

Gem::Specification.new do |spec|
  spec.name = "feedkit"
  spec.version = Feedkit::VERSION
  spec.authors = ["Ben Ubois"]
  spec.email = ["ben@benubois.com"]

  spec.summary = "Parse various sources into consistent format"
  spec.homepage = "https://github.com/feedbin/feedkit"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "feedjira", "~> 2.0"
  spec.add_runtime_dependency "twitter", "~> 7.0"
  spec.add_runtime_dependency "twitter-text", "~> 3.1.0"
  spec.add_runtime_dependency "http", "~> 4.4"
  spec.add_runtime_dependency "rchardet", "~> 1.8.0"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "minitest", "~> 5.14"
  spec.add_development_dependency "webmock", "~> 3.8"
end
