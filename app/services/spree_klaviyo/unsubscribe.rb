module SpreeKlaviyo
  class Unsubscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, subscriber:)
      @subscriber = subscriber

      klaviyo_integration.unsubscribe_user(email).tap do |result|
        subscriber.set_metafield('klaviyo.subscribed', false) if result.success?
      end
    end

    private

    attr_reader :subscriber

    delegate :email, to: :subscriber
  end
end
