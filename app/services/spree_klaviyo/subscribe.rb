module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, subscriber:)
      klaviyo_integration.subscribe_user(subscriber.email).tap do |result|
        subscriber.set_metafield('klaviyo.subscribed', true) if result.success?
      end
    end
  end
end
