module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user: nil, guest_id: nil, custom_properties: {})
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      unless user.present?
        return failure(false, 'No identifier (email or guest_id) provided') if guest_id.blank?
        return klaviyo_integration.create_guest_profile(guest_id: guest_id, custom_properties: custom_properties)
      else 
        if user.klaviyo_id.blank?
          fetch_profile_result = FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)

          if fetch_profile_result.success?
            return klaviyo_integration.update_profile(user, guest_id, custom_properties) if guest_id.present? || custom_properties.present?

            return fetch_profile_result
          end

          klaviyo_integration.create_profile(user, guest_id, custom_properties).tap do |result|
            user.update!(klaviyo_id: JSON.parse(result.value).dig('data', 'id')) if result.success?
          end
        end

        klaviyo_integration.update_profile(user, guest_id, custom_properties)
      end
    end
  end
end
