# encoding: UTF-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_klaviyo/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_klaviyo'
  s.version     = SpreeKlaviyo::VERSION
  s.summary     = "Official Spree Commerce Klaviyo email marketing integration"
  s.required_ruby_version = '>= 3.0'

  s.author    = 'Vendo Connect Inc.'
  s.email     = 'hello@spreecommerce.org'
  s.homepage  = 'https://github.com/spree/spree_klaviyo'
  s.license   = 'AGPL-3.0-or-later'

  s.files        = Dir["{app,config,db,lib,vendor}/**/*", "LICENSE.md", "Rakefile", "README.md"].reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'
  s.requirements << 'none'

  spree_opts = '>= 5.1.0.beta2'
  s.add_dependency 'spree', spree_opts
  s.add_dependency 'spree_storefront', spree_opts
  s.add_dependency 'spree_admin', spree_opts
  s.add_dependency 'spree_extension'

  s.add_development_dependency 'dotenv'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'spree_dev_tools'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'i18n-tasks'
end
