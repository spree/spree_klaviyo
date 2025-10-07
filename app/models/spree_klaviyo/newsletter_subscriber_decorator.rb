module SpreeKlaviyo
  module NewsletterSubscriberDecorator
    def self.prepended(base)
      base.after_commit :subscribe_to_klaviyo, if: :verified_at_previously_changed?

      def base.subscribe(email:, user: nil)
        subscriber = Spree::Newsletter::Subscribe.new(email: email, current_user: user).call
        return subscriber if subscriber.errors.any?
        return subscriber if subscriber.verified?

        # opt-in is cared by Klaviyo
        # we care about changing user's email marketing preference, though
        Spree::Newsletter::Verify.new(subscriber: subscriber).call
      end
    end

    private

    def subscribe_to_klaviyo
      klaviyo_integration = store_integration('klaviyo')
      return unless klaviyo_integration

      SpreeKlaviyo::SubscribeJob.perform_later(klaviyo_integration.id, id)
    end
  end

  Spree::NewsletterSubscriber.prepend(NewsletterSubscriberDecorator)
end


