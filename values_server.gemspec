# coding: utf-8

Gem::Specification.new do |spec|
  spec.name     = 'values_server'
  spec.version  = '0.' + `git rev-parse HEAD`
  spec.authors  = ["Roman Le Négrate"]
  spec.email    = ["roman.lenegrate@gmail.com"]
  spec.summary  = "Dynamic values server"
  spec.license  = "Unlicense"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = ["lib"]
end
