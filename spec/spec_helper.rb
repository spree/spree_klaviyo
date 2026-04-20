# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'
require 'dotenv/load'

require File.expand_path('../dummy/config/environment.rb', __FILE__)

require 'spree_dev_tools/rspec/spec_helper'
require 'spree_klaviyo/factories'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.before(:each) do
    # VCR cassetes are matched by body payload which contains spree user id
    allow_any_instance_of(SpreeKlaviyo::UserPresenter).to receive(:klaviyo_external_id).and_return(1)
  end
end
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }
