module SpreeKlaviyo
  class Configuration < Spree::Preferences::Configuration
    preference :klaviyo_api_url, :string, default: 'https://a.klaviyo.com/api/'
    preference :klaviyo_api_revision, :string, default: '2025-04-15'
    preference :klaviyo_api_open_timeout, :integer, default: 10
    preference :klaviyo_api_read_timeout, :integer, default: 10
  end
end
