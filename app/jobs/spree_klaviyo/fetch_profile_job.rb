module SpreeKlaviyo
  class FetchProfileJob < BaseJob
    NoProfileFoundError = Class.new(StandardError)

    def perform(klaviyo_integration_id, user_id)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)
      user = ::Spree.user_class.find(user_id)

      result = SpreeKlaviyo::FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)

      # Due to race condition let's give Klaviyo some time to create profile
      raise NoProfileFoundError if result.error == ::Spree::Integrations::Klaviyo::NO_PROFILE_FOUND
    end
  end
end
