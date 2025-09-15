module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:, resource: nil)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.subscribe_user(email).tap do |result|
        resource.update(klaviyo_subscribed: true) if result.success? && resource && !resource.klaviyo_subscribed?
      end
    end
  end
end
