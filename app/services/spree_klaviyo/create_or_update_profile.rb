module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:, guest_id: nil, custom_properties: {})
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      result = if user.klaviyo_id.blank?
        fetch_profile_result = FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)

        if fetch_profile_result.success?
          if guest_id.present?
            klaviyo_integration.update_profile(user, guest_id)
          else
            fetch_profile_result
          end
        else
          klaviyo_integration.create_profile(user).tap do |res|
            user.update!(klaviyo_id: JSON.parse(res.value).dig('data', 'id')) if res.success?
          end
        end
      else
        klaviyo_integration.update_profile(user)
      end

      if custom_properties.present? && result.success?
        klaviyo_id = user.reload.klaviyo_id
        update_profile_properties(klaviyo_integration, klaviyo_id, custom_properties)
      end

      result
    end

    private

    def update_profile_properties(klaviyo_integration, klaviyo_id, custom_properties)
      return if klaviyo_id.blank? || custom_properties.blank?

      payload = {
        data: {
          type: 'profile',
          id: klaviyo_id,
          attributes: {
            properties: custom_properties
          }
        }
      }

      klaviyo_integration.send(:client).patch_request("profiles/#{klaviyo_id}/", payload)
    end
  end
end
