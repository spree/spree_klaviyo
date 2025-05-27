module SpreeKlaviyo
  module UserDecorator
    def self.prepended(base)
      base.include ::SpreeKlaviyo::UserMethods
    end
  end
end

Spree::User.prepend(SpreeKlaviyo::UserDecorator) if defined?(Spree::User)
