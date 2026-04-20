module SpreeKlaviyo
  class Unsubscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:)
      klaviyo_integration.unsubscribe_user(email)
    end
  end
end
