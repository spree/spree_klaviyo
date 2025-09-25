module SpreeKlaviyo
  class SubscribeJob < BaseJob
    def perform(klaviyo_integration_id, email, resource_id, resource_type)
      resource = resource_type.classify.constantize.find(resource_id) if resource_id.present? && resource_type.present?

      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)

      SpreeKlaviyo::Subscribe.call(klaviyo_integration: klaviyo_integration, email: email, resource: resource)
    end
  end
end
