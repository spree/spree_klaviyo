module SpreeKlaviyo
  class CreateGuestProfileJob < BaseJob
    def perform(klaviyo_integration_id, order_id)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)
      order = ::Spree::Order.find(order_id)

      klaviyo_integration.create_guest_profile(email: order.email, address: order.bill_address)
    end
  end
end
