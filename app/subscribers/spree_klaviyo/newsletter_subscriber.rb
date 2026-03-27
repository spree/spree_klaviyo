module SpreeKlaviyo
  class NewsletterSubscriber < Spree::Subscriber
    subscribes_to 'newsletter_subscriber.created', 'newsletter_subscriber.deleted'

    on 'newsletter_subscriber.created', :handle_email_subscription
    on 'newsletter_subscriber.deleted', :handle_email_unsubscription

    private

    def handle_email_subscription(event)
      subscriber = Spree::NewsletterSubscriber.find_by(email: event.payload['email'])
      return if subscriber.blank?

      klaviyo_integration = klaviyo_integration(event)
      return if klaviyo_integration.blank?

      SpreeKlaviyo::SubscribeJob.perform_later(klaviyo_integration.id, subscriber.id)
    rescue StandardError => e
      Rails.error.report(e, context: { event_name: event.name }, source: 'spree_klaviyo')
      raise e
    end

    def handle_email_unsubscription(event)
      email = event.payload['email']
      return if email.blank?

      klaviyo_integration = klaviyo_integration(event)
      return if klaviyo_integration.blank?

      SpreeKlaviyo::UnsubscribeJob.perform_later(klaviyo_integration.id, email)
    rescue StandardError => e
      Rails.error.report(e, context: { event_name: event.name }, source: 'spree_klaviyo')
      raise e
    end

    def klaviyo_integration(event)
      store_id = event.store_id.presence || Spree::Store.default&.id
      return if store_id.blank?

      Spree::Integrations::Klaviyo.find_by(store_id: store_id)
    end
  end
end
