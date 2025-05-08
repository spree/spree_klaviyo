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

      SpreeKlaviyo::SubscribeJob.perform_later(integration.id, email, user_id)
    end

    def track_order_cancelled_event
      analytics_event_handler = SpreeKlaviyo::AnalyticsEventHandler.new(user: user, session: nil, request: nil, store: store)

      analytics_event_handler.handle_event('order_cancelled', { order: self })
    rescue StandardError => e
      Rails.error.report(
        e,
        context: { event_name: 'order_cancelled', record: { order: self } },
        source: 'spree.core'
      )
    end
  end

  Spree::Order.prepend(OrderDecorator)
end
