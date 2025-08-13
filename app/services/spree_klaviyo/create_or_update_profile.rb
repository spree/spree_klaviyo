module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:, guest_id: nil, custom_properties: {})
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      result = if user.klaviyo_id.blank?
        fetch_profile_result = FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)

        if fetch_profile_result.success?
          guest_id.present? ? klaviyo_integration.update_profile(user, guest_id) : fetch_profile_result
        else
          klaviyo_integration.create_profile(user).tap do |res|
            # Only persist klaviyo_id if this user record is already saved in DB.
            if res.success? && user.persisted?
              user.update_columns(klaviyo_id: JSON.parse(res.value).dig('data', 'id'))
            end
          end
        end
      else
        klaviyo_integration.update_profile(user)
      end

      if custom_properties.present? && result.success?
        # Determine the Klaviyo profile id to update.
        klaviyo_id = user.persisted? ? user.reload.klaviyo_id : nil

        # Fallback: extract id from response payload if still blank.
        if klaviyo_id.blank?
          begin
            parsed = JSON.parse(result.value)
            klaviyo_id = parsed.dig('data', 0, 'id') || parsed.dig('data', 'id')
          rescue JSON::ParserError
            klaviyo_id = nil
          end
        end
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
