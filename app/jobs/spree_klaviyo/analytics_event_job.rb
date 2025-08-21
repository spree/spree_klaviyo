module SpreeKlaviyo
  class AnalyticsEventJob < BaseJob
    def perform(klaviyo_integration_id, event_name, record, email, guest_id = nil)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)

      SpreeKlaviyo::CreateEvent.call(
        klaviyo_integration: klaviyo_integration,
        event: event_name,
        resource: record,
        email: email,
        guest_id: guest_id
      )
    end
  end
end
