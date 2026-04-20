module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:, guest_id: nil)
      return klaviyo_integration.update_profile(user) if user.klaviyo_id.present?

      get_klaviyo_id = FetchAndStoreUserKlaviyoId.call(klaviyo_integration: klaviyo_integration, user: user)

      if get_klaviyo_id.success?
        klaviyo_integration.update_profile(user, guest_id)
      else
        klaviyo_integration.create_profile(user, guest_id).tap do |result|
          user.update!(klaviyo_id: JSON.parse(result.value).dig('data', 'id')) if result.success?
        end
      end
    end
  end
end
