# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'
require 'dotenv/load'

require File.expand_path('../dummy/config/environment.rb', __FILE__)

require 'spree_dev_tools/rspec/spec_helper'
require 'spree_klaviyo/factories'

RSpec.configure do |config|
  config.before(:suite) do
    SpreeKlaviyo::MetafieldMigration.ensure_klaviyo_subscribed_definition!
  end
end
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }