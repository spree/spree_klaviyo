module SpreeKlaviyo
  class CreateBackInStockSubscriptionJob < BaseJob
    def perform(klaviyo_integration_id, email, variant_id)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)

      SpreeKlaviyo::CreateBackInStockSubscription.call(
        klaviyo_integration: klaviyo_integration,
        email: email,
        variant_id: variant_id
      )
    end
  end
end
