module SpreeKlaviyo
  # Job for processing multiple Klaviyo analytics events in batch asynchronously
  # This is useful for tracking multiple line items or bulk operations
  class BulkAnalyticsEventJob < BaseJob
    queue_as SpreeKlaviyo::Config[:job_queue]

    # Process multiple analytics events in batch
    # @param events [Array<Hash>] Array of event data hashes
    #   Each hash should contain: event_name, customer_properties, event_properties, time
    def perform(events)
      return unless SpreeKlaviyo::Config[:enabled]
      return if events.blank?

      # Find active Klaviyo integration
      integration = find_active_klaviyo_integration
      return unless integration

      # Process each event
      events.each do |event_data|
        process_single_event(integration, event_data)
      end
    rescue StandardError => e
      log_error("bulk_events", e.message)
      # Don't re-raise to avoid infinite retries
    end

    private

    def process_single_event(integration, event_data)
      event_name = event_data[:event_name]
      customer_properties = event_data[:customer_properties]
      event_properties = event_data[:event_properties]
      time = event_data[:time]

      result = integration.create_event(
        event: event_name,
        resource: event_properties[:resource],
        email: customer_properties[:email],
        guest_id: customer_properties[:guest_id]
      )

      if result.failure?
        log_error(event_name, result.value)
      end
    rescue StandardError => e
      log_error(event_data[:event_name] || "unknown", e.message)
    end

    def find_active_klaviyo_integration
      ::Spree::Integrations::Klaviyo.active.first
    end

    def log_error(event_name, error_message)
      Rails.logger.error(
        "SpreeKlaviyo: Failed to track event #{event_name}: #{error_message}"
      )
    end
  end
end
