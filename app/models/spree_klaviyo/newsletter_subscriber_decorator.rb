module SpreeKlaviyo
  module NewsletterSubscriberDecorator
    def self.prepended(base)
      base.include ::SpreeKlaviyo::SubscribableResource

      base.after_commit :subscribe_to_klaviyo, if: :verified_at_previously_changed?

      def base.needs_verification?
        false
      end
    end

    private

    def marketing_opt_in_changed?
      return false if klaviyo_subscribed? || user.nil?

      user.saved_change_to_accepts_email_marketing? && user.accepts_email_marketing?
    end
  end

  Spree::NewsletterSubscriber.prepend(NewsletterSubscriberDecorator)
end


