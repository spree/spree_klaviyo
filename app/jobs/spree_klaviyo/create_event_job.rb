module SpreeKlaviyo
  class CreateEventJob < BaseJob
    def perform(klaviyo_integration_id, event, resource_id, resource_type, email, guest_id = nil)
      resource = resource_type.classify.constantize.find(resource_id)
      klaviyo_integration = Spree::Integration.find(klaviyo_integration_id)

      SpreeKlaviyo::CreateEvent.call(klaviyo_integration: klaviyo_integration, event: event, resource: resource, email: email, guest_id: guest_id)
    end
  end
end
