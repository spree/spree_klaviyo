require 'vcr'
require 'webmock/rspec'

WebMock.disable_net_connect!(net_http_connect_on_start: true, allow_localhost: true)

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = false
  c.cassette_library_dir = File.join(SpreeKlaviyo::Engine.root, 'spec', 'vcr')
  c.hook_into :webmock
  c.ignore_localhost = true
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :new_episodes }
  c.filter_sensitive_data('<KLAVIYO_PUBLIC_API_KEY>') { ENV['KLAVIYO_PUBLIC_API_KEY'] }
  c.filter_sensitive_data('<KLAVIYO_PRIVATE_API_KEY>') { ENV['KLAVIYO_PRIVATE_API_KEY'] }
  c.filter_sensitive_data('<KLAVIYO_DEFAULT_NEWSLETTER_LIST_ID>') { ENV['KLAVIYO_DEFAULT_NEWSLETTER_LIST_ID'] }
end
