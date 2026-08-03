module SpreeKlaviyo
  module NewsletterSubscriberDecorator
    def self.prepended(base)
      # When an active Klaviyo integration owns opt-in for the store, verify the
      # subscriber immediately so Spree skips its own double opt-in email and both
      # systems agree the subscriber is on. Klaviyo's list handles confirmation.
      base.after_create -> { Spree::Newsletter::Verify.new(subscriber: self).call },
                        if: -> { !verified? && store_id.present? && Spree::Integrations::Klaviyo.active.exists?(store_id: store_id) }
    end
  end
end

Spree::NewsletterSubscriber.prepend(SpreeKlaviyo::NewsletterSubscriberDecorator)
