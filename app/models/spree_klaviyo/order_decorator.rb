module SpreeKlaviyo
  module OrderDecorator
    def self.prepended(base)
      base.state_machine.after_transition to: :complete, do: :subscribe_user_to_klaviyo_newsletter
      base.state_machine.after_transition to: :canceled, do: :track_order_cancelled_event
    end

    def subscribe_user_to_klaviyo_newsletter
      return unless accept_marketing?

      return if user&.klaviyo_subscribed?

      integration = store_integration('klaviyo')
      return if integration.blank?

      return if user&.instance_variable_get(:@subscribing_via_user)

      SpreeKlaviyo::SubscribeJob.perform_later(integration.id, email, user_id)
    end

    def track_order_cancelled_event
      klaviyo_integration = store.integrations.active.find_by(type: 'Spree::Integrations::Klaviyo')
      return if klaviyo_integration.nil?

      klaviyo_integration.create_event(event: 'Order Cancelled', resource: self, email: email)
    rescue StandardError => e
      Rails.error.report(
        e,
        context: { event_name: 'order_cancelled', record: { order: self } },
        source: 'spree.core'
      )
    end
  end

  ::Spree::Order.prepend(OrderDecorator)
end
