source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails-controller-testing'

spree_opts = { 'path': ENV['SPREE_PATH'] } if ENV['SPREE_PATH'].to_s.strip != ''

gem 'spree', '>= 5.4.0.beta', spree_opts || {}
gem 'spree_admin', '>= 5.4.0.beta', spree_opts || {}
gem 'spree_dev_tools', '>= 0.6.0.rc1'
gem 'spree_storefront', require: false

if ENV['DB'] == 'mysql'
  gem 'mysql2'
elsif ENV['DB'] == 'postgres'
  gem 'pg'
else
  gem 'sqlite3'
end

gem 'propshaft'

gemspec
