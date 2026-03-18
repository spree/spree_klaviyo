module SpreeKlaviyo
  class KlaviyoNewsletterSubscriber < Spree::Subscriber
    subscribes_to 'order.completed'

    on 'order.completed', :subscribe_user_to_klaviyo_newsletter

    private

    def subscribe_user_to_klaviyo_newsletter(event)
      order = Spree::Order.find_by(id: event.payload['id'])
      return unless order
      return unless order.accept_marketing?
      return if order.user&.klaviyo_subscribed?

      integration = Spree::Integrations::Klaviyo.find_by(store_id: order.store_id)
      return if integration.blank?

      SpreeKlaviyo::SubscribeJob.perform_later(integration.id, order.email, order.user_id)
    rescue StandardError => e
      Rails.error.report(e, context: { event_name: 'order_completed' }, source: 'spree_klaviyo')
    end
  end
end
