module SpreeKlaviyo
  class Unsubscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:, resource: nil)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.unsubscribe_user(email).tap do |result|
        next unless result.success?
        next unless resource
        next unless resource.klaviyo_subscribed?

        resource.update(klaviyo_subscribed: false)
      end
    end
  end
end
