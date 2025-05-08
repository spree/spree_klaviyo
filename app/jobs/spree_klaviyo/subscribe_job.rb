module SpreeKlaviyo
  class SubscribeJob < BaseJob
    def perform(klaviyo_integration_id, email, user_id = nil)
      user = Spree.user_class.find(user_id) if user_id.present?
      klaviyo_integration = Spree::Integrations::Klaviyo.find(klaviyo_integration_id)

      SpreeKlaviyo::Subscribe.call(klaviyo_integration: klaviyo_integration, email: email, user: user)
    end
  end
end
