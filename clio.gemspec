# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clio/version'

Gem::Specification.new do |spec|
  spec.name          = 'clio'
  spec.version       = Clio::VERSION
  spec.authors       = ['Rachel King']
  spec.email         = ['rachel.b.king@gmail.com']

  spec.summary       = 'Back up a variety of social media accounts.'
  spec.homepage      = 'https://github.com/macroscopicentric/clio'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.2.1'

  spec.add_dependency 'anyway_config', '~> 2.5'
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'twitter', '~> 6.0'

  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 1.57'
end
