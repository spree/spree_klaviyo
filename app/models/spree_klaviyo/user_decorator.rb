module SpreeKlaviyo
  module UserDecorator
    def self.prepended(base)
      base.include ::SpreeKlaviyo::SubscribableResource
    end
  end
end

Spree.user_class.prepend(SpreeKlaviyo::UserDecorator) if Spree.user_class.present?
