module SpreeKlaviyo
  module UserDecorator
    def self.prepended(base)
      base.include ::SpreeKlaviyo::SubscribableResource
    end

    private

    def marketing_opt_in_changed?
      return false if klaviyo_subscribed?

      saved_change_to_accepts_email_marketing? && accepts_email_marketing?
    end
  end
end

Spree.user_class.prepend(SpreeKlaviyo::UserDecorator) if Spree.user_class.present?
