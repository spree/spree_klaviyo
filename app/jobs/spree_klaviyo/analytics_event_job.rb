module SpreeKlaviyo
  class AnalyticsEventJob < BaseJob
    def perform(klaviyo_integration_id, event_name, resource_type, resource_id, email, guest_id = nil)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)
      record = load_record(resource_type, resource_id)

      SpreeKlaviyo::CreateEvent.call(
        klaviyo_integration: klaviyo_integration,
        event: event_name,
        resource: record,
        email: email,
        guest_id: guest_id
      )
    end

    private

    def load_record(resource_type, resource_id)
      return nil if resource_type.nil?
      return resource_id if resource_type == 'String'

      resource_type.constantize.find(resource_id)
    end
  end
end
