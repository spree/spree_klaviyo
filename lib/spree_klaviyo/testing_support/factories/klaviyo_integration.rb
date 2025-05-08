FactoryBot.define do
  factory :klaviyo_integration, class: Spree::Integrations::Klaviyo do
    active { true }
    preferred_klaviyo_public_api_key { ENV.fetch("KLAVIYO_PUBLIC_API_KEY", "1234") }
    preferred_klaviyo_private_api_key { ENV.fetch("KLAVIYO_PRIVATE_API_KEY", "1234567899") }
    preferred_default_newsletter_list_id { ENV.fetch("KLAVIYO_DEFAULT_NEWSLETTER_LIST_ID", "1234") }
    store { Spree::Store.default }
  end
end
