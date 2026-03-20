module SpreeKlaviyo
  class UnsubscribeJob < BaseJob
    def perform(klaviyo_integration_id, subscriber_id)
      klaviyo_integration = ::Spree::Integrations::Klaviyo.find(klaviyo_integration_id)
      subscriber = Spree::NewsletterSubscriber.find_by(id: subscriber_id)
      return unless subscriber

      SpreeKlaviyo::Unsubscribe.call(
        klaviyo_integration: klaviyo_integration,
        subscriber: subscriber
      )
    end
  end
end
