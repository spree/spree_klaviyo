module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:, resource: nil)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.subscribe_user(email).tap do |result|
        next unless resource.try(:klaviyo_subscribed?) == false
        next unless result.success?

        resource.update(klaviyo_subscribed: true)
      end
    end
  end
end
