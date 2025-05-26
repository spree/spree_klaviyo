module SpreeKlaviyo
  class FetchProfile < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, user:)
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      return success(user.klaviyo_id) if user.klaviyo_id.present?

      klaviyo_integration.fetch_profile(email: user.email).tap do |result|
        user.update!(klaviyo_id: JSON.parse(result.value)['data'].first['id']) if result.success?
      end
    end
  end
end
