lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lowkiq/version"

Gem::Specification.new do |spec|
  spec.name          = "lowkiq"
  spec.version       = Lowkiq::VERSION
  spec.authors       = ["Mikhail Kuzmin"]
  spec.email         = ["m.kuzmin@darkleaf.ru"]

  spec.summary       = %q{Lowkiq}
  spec.description   = %q{Lowkiq}
  spec.homepage      = "https://github.com/bia-technologies/lowkiq"
  spec.licenses      = ['LGPL', 'EULA']

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(spec|frontend|examples|doc)/}) }
      .push('assets/app.js')
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "redis", ">= 4.0.1", "< 5"
  spec.add_dependency "connection_pool", "~> 2.2", ">= 2.2.2"
  spec.add_dependency "rack", ">= 1.5.0"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 12.3.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-mocks", "~> 3.8"
  spec.add_development_dependency "rack-test", "~> 1.1"
  spec.add_development_dependency "pry-byebug", "~> 3.10.1"
end
