module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user: nil, guest_id: nil, custom_properties: {})
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      unless user.present?
        return failure(false, 'No identifier (guest_id) provided') if guest_id.blank?
        return klaviyo_integration.create_guest_profile(guest_id: guest_id, custom_properties: custom_properties)
      end

      if user&.klaviyo_id.blank?
        fetch_profile_result = FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)

        if fetch_profile_result.success?
          fetched_id = JSON.parse(fetch_profile_result.value).dig('data', 0, 'id')
          user.update!(klaviyo_id: fetched_id) if fetched_id.present?

          return klaviyo_integration.update_profile(user, guest_id: guest_id, custom_properties: custom_properties) if guest_id.present? || custom_properties.present?
          return fetch_profile_result
        end

        create_result = klaviyo_integration.create_profile(user, guest_id: guest_id, custom_properties: custom_properties)

        if create_result.success?
          user.update!(klaviyo_id: JSON.parse(create_result.value).dig('data', 'id'))
          return create_result
        else
          error_response = JSON.parse(create_result.value) rescue {}
          dup_id = error_response.dig('errors', 0, 'meta', 'duplicate_profile_id')
          if dup_id
            user.update!(klaviyo_id: dup_id)
            return klaviyo_integration.update_profile(user, guest_id: guest_id, custom_properties: custom_properties)
          end

          return create_result
        end
      end
      klaviyo_integration.update_profile(user, guest_id: guest_id, custom_properties: custom_properties)
    end
  end
end
