# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'
require 'dotenv/load'

require File.expand_path('dummy/config/environment.rb', __dir__)

require 'spree_dev_tools/rspec/spec_helper'
require 'spree_klaviyo/factories'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }

Spree::LegacyUser.include SpreeKlaviyo::UserMethods
