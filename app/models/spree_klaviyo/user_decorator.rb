module SpreeKlaviyo
  module UserDecorator
    def self.prepended(base)
      base.store_accessor :private_metadata, :klaviyo_id
    end

    def create_or_update_klaviyo_profile(klaviyo_integration:)
      SpreeKlaviyo::CreateOrUpdateProfileJob.perform_later(klaviyo_integration.id, id)
    end
  end
end

Spree.user_class.prepend(SpreeKlaviyo::UserDecorator) if Spree.user_class.present?
