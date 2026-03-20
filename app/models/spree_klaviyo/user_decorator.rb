module SpreeKlaviyo
  module UserDecorator
    def self.prepended(base)
      base.store_accessor :private_metadata, :klaviyo_id
      base.store_accessor :private_metadata, :klaviyo_visitor_id
    end
  end
end

Spree.user_class&.prepend(SpreeKlaviyo::UserDecorator)

