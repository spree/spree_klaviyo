module SpreeKlaviyo
  module UserRegistrationsControllerDecorator
    def self.prepended(base)
      base.include ::Spree::AnalyticsHelper
      base.after_action :create_or_update_klaviyo_profile, only: :create, if: :try_spree_current_user
    end

    private

    def create_or_update_klaviyo_profile
      return if store_integration('klaviyo').nil?

      try_spree_current_user.create_or_update_klaviyo_profile(
        klaviyo_integration: store_integration('klaviyo'),
        guest_id: visitor_id
      )
    end
  end
end

Spree::UserRegistrationsController.prepend(SpreeKlaviyo::UserRegistrationsControllerDecorator) if defined?(Spree::UserRegistrationsController)
