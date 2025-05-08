module SpreeKlaviyo
  class CreateEvent < Base
    prepend Spree::ServiceModule::Base

    def call(klaviyo_integration:, event:, resource:, email:, guest_id: nil)
      return failure(false, Spree.t('admin.integrations.klaviyo.not_found')) unless klaviyo_integration

      klaviyo_integration.create_event(
        event: event,
        resource: resource,
        email: email,
        guest_id: guest_id
      )
    end
  end
end
