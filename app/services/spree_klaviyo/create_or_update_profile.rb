module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:, guest_id: nil)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      if user.klaviyo_id.blank?
        fetch_profile_result = FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)

        if fetch_profile_result.success?
          return klaviyo_integration.update_profile(user, guest_id) if guest_id.present?

          return fetch_profile_result
        end

        klaviyo_integration.create_profile(user).tap do |result|
          user.update!(klaviyo_id: JSON.parse(result.value).dig('data', 'id')) if result.success?
        end
      end

      klaviyo_integration.update_profile(user)
    end
  end
end
