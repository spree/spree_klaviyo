module SpreeKlaviyo
  class CreateBackInStockSubscriptionJob < BaseJob
    def perform(klaviyo_integration_id, email, variant_id)
      variant = Spree::Variant.find(variant_id)
      klaviyo_integration = Spree::Integrations::Klaviyo.find(klaviyo_integration_id)

      klaviyo_integration.create_back_in_stock_subscription(email: email, variant_id: variant.id)
    end
  end
end
