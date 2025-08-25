module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:, user: nil)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.subscribe_user(email).tap do |result|
        user.update(klaviyo_subscribed: true) if result.success? && user && !user.klaviyo_subscribed?
      end
    end
  end
end
