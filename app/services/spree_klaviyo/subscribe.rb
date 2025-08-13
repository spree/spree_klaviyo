module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:, user: nil, custom_properties: {})
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.subscribe_user(email).tap do |result|
        if result.success?
          user&.update(klaviyo_subscribed: true) if user && !user.klaviyo_subscribed?

          if custom_properties.present?
            target_user = user || ::Spree.user_class.find_or_initialize_by(email: email)

            SpreeKlaviyo::CreateOrUpdateProfile.call(
              klaviyo_integration: klaviyo_integration,
              user: target_user,
              custom_properties: custom_properties
            )
          end
        end
      end
    end
  end
end
