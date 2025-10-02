module SpreeKlaviyo
  module NewsletterSubscriberDecorator
    def self.prepended(base)
      base.store_accessor :private_metadata, :klaviyo_subscribed

      base.after_commit :subscribe_to_klaviyo, if: :verified_at_previously_changed?

      def base.needs_verification?
        false
      end

      def base.subscribe(email:, user: nil)
        Spree::Newsletter::Subscribe.new(email: email, current_user: user).call.tap do |subscriber|
          next subscriber if subscriber.errors.any?
          next subscriber if subscriber.verified?

          # opt-in is cared by Klaviyo
          # we care about changing user's email marketing preference, though
          Spree::Newsletter::Verify.new(subscriber: subscriber).call
        end
      end
    end

    def klaviyo_subscribed?
      klaviyo_subscribed.to_b
    end

    private

    def subscribe_to_klaviyo
      klaviyo_integration = store_integration('klaviyo')
      return unless klaviyo_integration

      SpreeKlaviyo::SubscribeJob.perform_later(klaviyo_integration.id, id)
    end

    def marketing_opt_in_changed?
      return false if klaviyo_subscribed? || user.nil?

      user.saved_change_to_accepts_email_marketing? && user.accepts_email_marketing?
    end
  end

  Spree::NewsletterSubscriber.prepend(NewsletterSubscriberDecorator)
end


