module SpreeKlaviyo
  # Job for processing single Klaviyo analytics events asynchronously
  # This eliminates 100-400ms web request delays by moving API calls to background processing
  class AnalyticsEventJob < BaseJob
    queue_as SpreeKlaviyo::Config[:job_queue]

    # Process a single analytics event
    # @param event_name [String] The name of the event to track
    # @param customer_properties [Hash] Customer properties for the event
    # @param event_properties [Hash] Event-specific properties
    # @param time [Time, nil] Optional timestamp for the event
    def perform(event_name, customer_properties, event_properties, time = nil)
      return unless SpreeKlaviyo::Config[:enabled]

      # Find active Klaviyo integration
      integration = find_active_klaviyo_integration
      return unless integration

      # Create and send the event
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
      log_error(event_name, e.message)
      # Don't re-raise to avoid infinite retries
    end

    private

    def find_active_klaviyo_integration
      # This is a simplified approach - in a real implementation, you might want to
      # pass the integration ID or store ID as a parameter
      ::Spree::Integrations::Klaviyo.active.first
    end

    def log_error(event_name, error_message)
      Rails.logger.error(
        "SpreeKlaviyo: Failed to track event #{event_name}: #{error_message}"
      )
    end
  end
end
