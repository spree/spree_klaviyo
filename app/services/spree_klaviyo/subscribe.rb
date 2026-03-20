module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, subscriber:)
      @subscriber = subscriber

      klaviyo_integration.subscribe_user(email).tap do |result|
        subscriber.set_metafield('klaviyo.subscribed', true) if result.success?
      end
    end

    private

    attr_reader :subscriber

    delegate :email, to: :subscriber
  end
end
