
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "feedbin/parser/version"

Gem::Specification.new do |spec|
  spec.name          = "feedbin-parser"
  spec.version       = Feedbin::Parser::VERSION
  spec.authors       = ["Ben Ubois"]
  spec.email         = ["ben@benubois.com"]

  spec.summary       = %q{Parse various sources into consistent format}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "feedjira", "~> 2.0"
  spec.add_runtime_dependency "curb", "~> 0.9"
  spec.add_runtime_dependency "twitter", "~> 6.2"
  spec.add_runtime_dependency "twitter-text", "~> 2.1"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
