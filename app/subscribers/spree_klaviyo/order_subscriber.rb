module SpreeKlaviyo
  class OrderSubscriber < Spree::Subscriber
    subscribes_to 'order.canceled'

    on 'order.canceled', :track_order_cancelled_event

    private

    def track_order_cancelled_event(event)
      order = Spree::Order.find_by_param(event.payload['id'])
      return unless order

      integration = Spree::Integrations::Klaviyo.find_by(store_id: order.store_id)
      return if integration.blank?

      SpreeKlaviyo::AnalyticsEventJob.perform_later(
        integration.id, 'Order Cancelled', Spree::Order.name, order.id, order.email
      )
    end
  end
end
