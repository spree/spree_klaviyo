FactoryBot.define do
  factory :klaviyo_integration, class: Spree::Integrations::Klaviyo do
    active { true }
    preferred_klaviyo_public_api_key { SpreeKlaviyo::Testing.default_public_api_key }
    preferred_klaviyo_private_api_key { SpreeKlaviyo::Testing.default_private_api_key }
    preferred_default_newsletter_list_id { SpreeKlaviyo::Testing.default_newsletter_list_id }
    store { Spree::Store.default }
  end
end
