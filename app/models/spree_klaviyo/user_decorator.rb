module SpreeKlaviyo
  module UserDecorator
    def self.prepended(base)
      base.store_accessor :private_metadata, :klaviyo_id
      base.store_accessor :private_metadata, :klaviyo_subscribed
      base.store_accessor :private_metadata, :klaviyo_visitor_id
    end

    def klaviyo_subscribed?
      klaviyo_subscribed.to_b
    end
  end
end

Spree.user_class&.prepend(SpreeKlaviyo::UserDecorator)

