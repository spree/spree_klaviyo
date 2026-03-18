module SpreeKlaviyo
  class MergeVisitorProfileJob < BaseJob
    def perform(klaviyo_integration_id, user_id, visitor_id)
      user = ::Spree.user_class.find(user_id)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)

      CreateOrUpdateProfile.call(
        klaviyo_integration: klaviyo_integration,
        user: user,
        guest_id: visitor_id
      )
    end
  end
end
