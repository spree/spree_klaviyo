module SpreeKlaviyo
  class CreateBackInStockSubscription < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:, variant_id:)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.create_back_in_stock_subscription(email: email, variant_id: variant_id)
    end
  end
end
