module SpreeKlaviyo
  module AddressesControllerDecorator
    def self.prepended(base)
      base.include Spree::IntegrationsHelper

      base.after_action :create_or_update_klaviyo_profile, only: %i[create update]
    end

    def create_or_update_klaviyo_profile
      return unless store_integration('klaviyo').present?
      return unless @address.valid?

      try_spree_current_user.create_or_update_klaviyo_profile(klaviyo_integration: store_integration('klaviyo'))
    end
  end
end

Spree::AddressesController.prepend(SpreeKlaviyo::AddressesControllerDecorator)
