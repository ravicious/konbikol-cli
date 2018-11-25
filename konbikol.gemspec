
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "konbikol/version"

Gem::Specification.new do |spec|
  spec.name          = "konbikol"
  spec.version       = Konbikol::VERSION
  spec.authors       = ["Rafał Cieślak"]
  spec.email         = ["ravicious@gmail.com"]

  spec.summary       = "Converts Polish train tickets to iCalendar events."
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/ravicious/konbikol"
  spec.license       = "GPL-3.0-or-later"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = spec.homepage
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_dependency "icalendar", "~> 2.5.1"
  spec.add_dependency "pdf-reader", "~> 2.1.0"
  spec.add_dependency "tzinfo", "~> 1.2.5"
  spec.add_dependency "unidecoder", "~> 1.1.2"
end
