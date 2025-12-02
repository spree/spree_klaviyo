module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, subscriber:)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.subscribe_user(subscriber.email).tap do |result|
        next unless result.success?

        subscriber.set_metafield('klaviyo.subscribed', true)
      end
    end
  end
end
