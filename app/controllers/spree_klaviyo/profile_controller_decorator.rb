module SpreeKlaviyo
  module ProfileControllerDecorator
    def self.prepended(base)
      base.before_action :create_klaviyo_profile, only: :update
    end

    private

    def create_klaviyo_profile
      return unless store_integration('klaviyo').present?
      return unless @user.valid?

      @user.create_or_update_klaviyo_profile(klaviyo_integration: store_integration('klaviyo'))
    end
  end
end

Spree::Account::ProfileController.prepend(SpreeKlaviyo::ProfileControllerDecorator)
