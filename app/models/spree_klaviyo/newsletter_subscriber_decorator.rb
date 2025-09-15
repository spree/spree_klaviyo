module SpreeKlaviyo
  module NewsletterSubscriberDecorator
    def self.prepended(base)
      base.include ::SpreeKlaviyo::SubscribableResource
    end

    private

    def marketing_opt_in_changed?
      return false if klaviyo_subscribed? || user.nil?

      user.saved_change_to_accepts_email_marketing? && user.accepts_email_marketing?
    end
  end

  Spree::NewsletterSubscriber.prepend(NewsletterSubscriberDecorator)
end


