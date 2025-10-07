module SpreeKlaviyo
  class FetchProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_id = user.get_metafield('klaviyo.id')&.value
      return success(klaviyo_id) if klaviyo_id.present?

      klaviyo_integration.fetch_profile(email: user.email).tap do |result|
        next if result.failure?

        id = JSON.parse(result.value)['data'].first['id'].presence
        user.set_metafield('klaviyo.id', id)
      end
    end
  end
end
