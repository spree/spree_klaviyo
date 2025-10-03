module SpreeKlaviyo
  class CreateOrUpdateProfileJob < BaseJob
    def perform(klaviyo_integration_id, user_id)
      user = ::Spree.user_class.find(user_id)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)

      SpreeKlaviyo::CreateOrUpdateProfile.call(klaviyo_integration: klaviyo_integration, user: user, guest_id: guest_id)
    end
  end
end
