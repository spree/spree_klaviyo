module SpreeKlaviyo
  class FetchProfileJob < BaseJob
    NoProfileFoundError = Class.new(StandardError)

    def perform(klaviyo_integration_id, resource_id, resource_type=Spree.user_class)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)
      resource = resource_type.constantize.find(resource_id)

      result = SpreeKlaviyo::FetchProfile.call(klaviyo_integration: klaviyo_integration, resource: resource)

      # Due to race condition let's give Klaviyo some time to create profile
      raise NoProfileFoundError if result.error == ::Spree::Integrations::Klaviyo::NO_PROFILE_FOUND
    end
  end
end
