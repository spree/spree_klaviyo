module SpreeKlaviyo
  class AnalyticsEventHandler < ::Spree::BaseAnalyticsEventHandler
    def client
      @client ||= store.integrations.active.find_by(type: 'Spree::Integrations::Klaviyo')
    end

    def handle_event(event_name, properties)
      return if client.blank?

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
                 email ||= properties[:email]
                 SpreeKlaviyo::SubscribeJob.perform_later(client.id, email, user&.id)
                 nil
               when 'unsubscribed_from_newsletter'
                 email ||= properties[:email]
                 SpreeKlaviyo::UnsubscribeJob.perform_later(client.id, email, user&.id)
                 nil
               end

      return if email.blank? && identity_hash[:visitor_id].blank?

      resource_type = record.nil? ? nil : (record.is_a?(String) ? 'String' : record.class.name)
      resource_id = record.is_a?(String) ? record : record&.id

      SpreeKlaviyo::AnalyticsEventJob.perform_later(client.id, event_human_name(event_name), resource_type, resource_id, email, identity_hash[:visitor_id])
    end
  end
end
