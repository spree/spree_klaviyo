module SpreeKlaviyo
  class NewsletterSubscriber < Spree::Subscriber
    subscribes_to 'newsletter_subscriber.created', 'newsletter_subscriber.deleted'

    on 'newsletter_subscriber.created', :handle_email_subscription
    on 'newsletter_subscriber.deleted', :handle_email_unsubscription

    private

    def handle_email_subscription(event)
      prefix_id = event.payload['id']
      return if prefix_id.blank?

      subscriber = Spree::NewsletterSubscriber.find_by_prefix_id(prefix_id)
      return if subscriber.blank?

      integration = Spree::Integrations::Klaviyo.find_by(store_id: subscriber.store_id)
      return if integration.blank?

      SpreeKlaviyo::SubscribeJob.perform_later(integration.id, subscriber.id)
    end

    def handle_email_unsubscription(event)
      email = event.payload['email']
      return if email.blank? || event.store_id.blank?

      integration = Spree::Integrations::Klaviyo.find_by(store_id: event.store_id)
      return if integration.blank?

      SpreeKlaviyo::UnsubscribeJob.perform_later(integration.id, email)
    end
  end
end
