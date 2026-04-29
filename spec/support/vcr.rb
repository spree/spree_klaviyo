require 'vcr'
require 'json'
require 'webmock/rspec'
require 'spree_klaviyo/testing_support/defaults'

WebMock.disable_net_connect!(net_http_connect_on_start: true, allow_localhost: true)

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = false
  c.cassette_library_dir = File.join(SpreeKlaviyo::Engine.root, 'spec', 'vcr')
  c.hook_into :webmock
  c.ignore_localhost = true
  c.register_request_matcher :normalized_body do |req1, req2|
    normalize = ->(body) do
      parsed = JSON.parse(body)
      list_data = parsed.dig("data", "relationships", "list", "data")
      list_data["id"] = "PLACEHOLDER" if list_data&.key?("id")
      attributes = parsed.dig("data", "attributes")
      attributes["external_id"] = "PLACEHOLDER" if attributes&.key?("external_id")
      profile_attributes = parsed.dig("data", "attributes", "profile", "data", "attributes")
      profile_attributes["external_id"] = "PLACEHOLDER" if profile_attributes&.key?("external_id")
      parsed
    rescue JSON::ParserError
      body
    end

    normalize.call(req1.body) == normalize.call(req2.body)
  end
  c.default_cassette_options = {
    allow_unused_http_interactions: false,
    record: :once,
    match_requests_on: [:method, :uri, :normalized_body]
  }
  c.filter_sensitive_data('<KLAVIYO_PUBLIC_API_KEY>') { SpreeKlaviyo::Testing.default_public_api_key }
  c.filter_sensitive_data('<KLAVIYO_PRIVATE_API_KEY>') { SpreeKlaviyo::Testing.default_private_api_key }
  c.filter_sensitive_data('KLAVIYO_DEFAULT_NEWSLETTER_LIST_ID') { SpreeKlaviyo::Testing.default_newsletter_list_id }
end
