module SpreeKlaviyo
  class Unsubscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.unsubscribe_user(email)
    end
  end
end
