module SpreeKlaviyo
  module UserDecorator
    def self.prepended(base)
      # todo: remove after the release, leaving it here for supporting existing jobs
      base.include ::SpreeKlaviyo::SubscribableResource
    end
  end
end

Spree.user_class.prepend(SpreeKlaviyo::UserDecorator) if Spree.user_class.present?
