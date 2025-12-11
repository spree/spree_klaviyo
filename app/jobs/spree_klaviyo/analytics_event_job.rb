module SpreeKlaviyo
  class AnalyticsEventJob < BaseJob
    def perform(klaviyo_integration_id, event_name, serialized_record, email, guest_id = nil)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)
      record = deserialize_record(serialized_record)

      SpreeKlaviyo::CreateEvent.call(
        klaviyo_integration: klaviyo_integration,
        event: event_name,
        resource: record,
        email: email,
        guest_id: guest_id
      )
    end

    private

    def deserialize_record(serialized_record)
      return nil if serialized_record.nil?
      return serialized_record if serialized_record.is_a?(String)

      serialized_record['class'].constantize.find(serialized_record['id'])
    end
  end
end
