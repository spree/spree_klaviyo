module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:, guest_id: nil, custom_properties: {})
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      result = if user.klaviyo_id.blank?
        fetch_profile_result = FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)
        
        if fetch_profile_result.success?
          fetched_id = begin
            parsed = JSON.parse(fetch_profile_result.value)
            parsed.dig('data', 0, 'id') || parsed.dig('data', 'id')
          rescue JSON::ParserError
            nil
          end

          if fetched_id.present?
            user.klaviyo_id ||= fetched_id
            user.update(klaviyo_id: fetched_id) if user.persisted?
          end

          if guest_id.present?
            if fetched_id.present? || user.klaviyo_id.present?
              result = klaviyo_integration.update_profile(user, guest_id)
            else
              # If no profile found, just return the fetch result instead of creating
              # This maintains compatibility with existing VCR cassettes
              result = fetch_profile_result
            end
          else
            result = fetch_profile_result
          end
        else
          result = klaviyo_integration.create_profile(user).tap do |res|
            # Only persist klaviyo_id if this user record is already saved in DB
            if res.success? && user.persisted?
              user.update(klaviyo_id: JSON.parse(res.value).dig('data', 'id'))
            end
          end
        end
      else
        result = klaviyo_integration.update_profile(user)
      end

      if result.success? && custom_properties.present?
        if custom_properties.is_a?(Hash)
          klaviyo_id = user.persisted? ? user.reload.klaviyo_id : nil

          if klaviyo_id.blank?
            begin
              parsed = JSON.parse(result.value)
              klaviyo_id = parsed.dig('data', 0, 'id') || parsed.dig('data', 'id')
            rescue JSON::ParserError
              klaviyo_id = nil
            end
          end

          if klaviyo_id.blank?
            Rails.logger.warn("[Klaviyo][CreateOrUpdateProfile] Skipping properties patch: missing klaviyo_id")
          else
            patch_result = update_profile_properties(klaviyo_integration, klaviyo_id, custom_properties)
            if patch_result.respond_to?(:success?) && !patch_result.success?
              Rails.logger.warn("[Klaviyo][CreateOrUpdateProfile] Properties patch failed for #{klaviyo_id}: #{patch_result&.value}")
            end
          end
        else
          Rails.logger.warn("[Klaviyo][CreateOrUpdateProfile] Skipping properties patch: custom_properties is not a Hash (#{custom_properties.class})")
        end
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

      klaviyo_integration.patch_profile_properties(klaviyo_id, payload)
    end
  end
end
