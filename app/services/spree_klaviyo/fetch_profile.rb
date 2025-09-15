module SpreeKlaviyo
  class FetchProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, resource:)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      return success(resource.klaviyo_id) if resource.klaviyo_id.present?

      klaviyo_integration.fetch_profile(email: resource.email).tap do |result|
        resource.update!(klaviyo_id: JSON.parse(result.value)['data'].first['id']) if result.success?
      end
    end
  end
end
