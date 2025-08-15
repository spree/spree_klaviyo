module SpreeKlaviyo
  class Subscribe < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, email:, user: nil, custom_properties: {})
      return failure(false, ::Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      result = klaviyo_integration.subscribe_user(email)
      
      if result.success?
        user&.update(klaviyo_subscribed: true) if user && !user.klaviyo_subscribed?
        
        if custom_properties.present?
          # Prefer provided user first, then lookup, then guest
          user_object = user || ::Spree.user_class.find_by(email: email) || SpreeKlaviyo::GuestUser.new(email: email)
          
          SpreeKlaviyo::CreateOrUpdateProfile.call(
            klaviyo_integration: klaviyo_integration,
            user: user_object,
            custom_properties: custom_properties
          )
        end
      else
        Rails.logger.warn("[Klaviyo][Subscribe] Failed subscribe for #{email}: #{result.value}")
      end
      
      result
    end
  end
end
