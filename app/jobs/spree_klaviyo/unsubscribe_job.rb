module SpreeKlaviyo
  class UnsubscribeJob < BaseJob
    def perform(klaviyo_integration_id, email)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)

      SpreeKlaviyo::Unsubscribe.call(klaviyo_integration: klaviyo_integration, email: email)
    end
  end
end
