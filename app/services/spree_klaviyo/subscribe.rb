module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, subscriber:)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration
      return if subscriber.klaviyo_subscribed?

      klaviyo_integration.subscribe_user(subscriber.email).tap do |result|
        next unless result.success?

        subscriber.update(klaviyo_subscribed: true)
      end
    end
  end
end
