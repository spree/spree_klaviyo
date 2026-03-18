module SpreeKlaviyo
  class FetchAndStoreUserKlaviyoId < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:)
      @klaviyo_integration = klaviyo_integration
      @user = user

      if user.klaviyo_id.present?
        return success(user.klaviyo_id)
      elsif fetch_profile.success?
        user.update!(klaviyo_id: JSON.parse(fetch_profile.value)['data'][0]['id'])
        return success(user.klaviyo_id)
      else
        return failure(false, fetch_profile.value)
      end
    end

    private

    attr_reader :klaviyo_integration, :user

    def fetch_profile
      @fetch_profile ||= klaviyo_integration.fetch_profile(email: user.email)
    end
  end
end
