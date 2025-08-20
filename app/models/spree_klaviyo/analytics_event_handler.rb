module SpreeKlaviyo
  class AnalyticsEventHandler < ::Spree::BaseAnalyticsEventHandler
    def client
      @client ||= store.integrations.active.find_by(type: 'Spree::Integrations::Klaviyo')
    end

    def handle_event(event_name, properties)
      return if client.blank?

      # Initialize email from user, but allow properties to override it
      email = user&.email.presence

      record = case event_name
               when 'product_viewed'
                 properties[:product]
               when 'product_list_viewed'
                 properties[:taxon]
               when 'product_searched'
                 properties[:query]
               when 'product_added', 'product_removed'
                 email ||= properties[:line_item].order.email
                 properties[:line_item].order
               when 'payment_info_entered'
                 email ||= properties[:order].email
                 properties[:order]
               when 'coupon_entered', 'coupon_removed'
                 email ||= properties[:order].email
                 properties[:order]
               when 'coupon_applied'
                 email ||= properties[:order].email
                 properties[:order]
               when 'coupon_denied'
                 email ||= properties[:order].email
                 properties[:order]
               when 'checkout_started'
                 email ||= properties[:order].email
                 properties[:order]
               when 'checkout_email_entered'
                 email = properties[:email]
                 properties[:order]
               when 'checkout_step_viewed', 'checkout_step_completed'
                 email ||= properties[:order].email
                 properties[:order]
               when 'order_completed'
                 email ||= properties[:order].email
                 properties[:order]
               when 'subscribed_to_newsletter'
                 # Use email from properties, fallback to user email
                 email = properties[:email] || user&.email
                 SpreeKlaviyo::SubscribeJob.perform_later(client.id, email, user&.id)
                 return # Exit early for newsletter events
               when 'unsubscribed_from_newsletter'
                 # Use email from properties, fallback to user email
                 email = properties[:email] || user&.email
                 SpreeKlaviyo::UnsubscribeJob.perform_later(client.id, email, user&.id)
                 return # Exit early for newsletter events
               end

      # Only return early if we have no email AND no visitor ID
      # This allows events to be tracked even without an email if there's a visitor ID
      return if email.blank? && identity_hash[:visitor_id].blank?

      # Use async tracking if enabled, otherwise fall back to sync
      if SpreeKlaviyo::Config[:async_tracking]
        enqueue_event(event_name, record, email, identity_hash[:visitor_id])
      else
        track_event_sync(event_name, record, email, identity_hash[:visitor_id])
      end
    end
    
    private

    # Enqueue event for async processing
    def enqueue_event(event_name, record, email, guest_id)
      customer_properties = { email: email, guest_id: guest_id }
      event_properties = { resource: record }

      SpreeKlaviyo::AnalyticsEventJob.perform_later(
        client.id,
        event_name,
        customer_properties,
        event_properties
      )
    end

    # Synchronous event tracking (fallback)
    def track_event_sync(event_name, record, email, guest_id)
      client.create_event(
        event: event_name, 
        resource: record, 
        email: email, 
        guest_id: guest_id
      )
    end
  end
end
