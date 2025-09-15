module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, resource:, guest_id: nil)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      if resource.klaviyo_id.blank?
        fetch_profile_result = FetchProfile.call(klaviyo_integration: klaviyo_integration, resource: resource)

        if fetch_profile_result.success?
          return klaviyo_integration.update_profile(resource, guest_id) if guest_id.present?

          return fetch_profile_result
        end

        klaviyo_integration.create_profile(resource).tap do |result|
          resource.update!(klaviyo_id: JSON.parse(result.value).dig('data', 'id')) if result.success?
        end
      end

      klaviyo_integration.update_profile(resource)
    end
  end
end
