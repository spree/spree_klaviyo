module SpreeKlaviyo
  class CreateOrUpdateProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:, guest_id: nil)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      if user.get_metafield('klaviyo.id').nil?
        fetch_profile_result = FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)

        if fetch_profile_result.success?
          return klaviyo_integration.update_profile(user, guest_id) if guest_id.present?

          return fetch_profile_result
        end

        klaviyo_integration.create_profile(user).tap do |result|
          next if result.failure?


          id = JSON.parse(result.value).dig('data', 'id').presence
          user.set_metafield('klaviyo.id', id) if id.present?
        end
      end

      klaviyo_integration.update_profile(user)
    end
  end
end
