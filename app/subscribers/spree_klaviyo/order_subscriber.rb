module SpreeKlaviyo
  class OrderSubscriber < Spree::Subscriber
    subscribes_to 'order.canceled'

    on 'order.canceled', :track_order_cancelled_event

    private

    def track_order_cancelled_event(event)
      order = Spree::Order.find_by(id: event.payload['id'])
      return unless order

      integration = Spree::Integrations::Klaviyo.find_by(store_id: order.store_id)
      return if integration.blank?

      SpreeKlaviyo::AnalyticsEventJob.perform_later(
        integration.id, 'Order Cancelled', 'Spree::Order', order.id, order.email
      )
    rescue StandardError => e
      Rails.error.report(e, context: { event_name: 'order_cancelled' }, source: 'spree_klaviyo')
    end
  end
end
