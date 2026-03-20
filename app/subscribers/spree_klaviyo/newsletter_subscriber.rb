module SpreeKlaviyo
  class NewsletterSubscriber < Spree::Subscriber
    subscribes_to 'newsletter_subscriber.subscribed'

    def handle(event)
      subscriber = find_subscriber(event)
      return if subscriber.blank?

      store_id = event.store_id.presence || Spree::Store.default&.id
      return if store_id.blank?

      klaviyo_integration = Spree::Integrations::Klaviyo.find_by(store_id: store_id)
      return if klaviyo_integration.blank?

      SpreeKlaviyo::SubscribeJob.perform_later(klaviyo_integration.id, subscriber.id)
    rescue StandardError => e
      Rails.error.report(e, context: { event_name: 'newsletter_subscriber.subscribed' }, source: 'spree_klaviyo')
    end

    private

    def find_subscriber(event)
      Spree::NewsletterSubscriber.find_by_param(event.payload['id'])
    end
  end
end
