# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spam/version'
require 'rbconfig'

Gem::Specification.new do |spec|
  spec.name          = 'SPAM'
  spec.version       = SPAM::VERSION
  spec.authors       = ['Levi Smith']
  spec.email         = ['atat@hearst.com']

  spec.summary       = 'SPAM (Smart Proxy Alb Manager) - CLI Tool to manage ALB
                        Listener and Rules for Foreman Smart Proxy Setups'
  spec.description   = ''
  spec.homepage      = 'https://github.com/hearstat/SPAM'

  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-elasticloadbalancingv2', '~> 1.0.0.rc6'
  spec.add_dependency 'httparty'
  spec.add_dependency 'thor', '~> 0.19.0'

  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'debase', '~>0.2.2.beta10'
  spec.add_development_dependency 'ruby-debug-ide', '~> 0.6.1.beta4'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'simplecov'
end
