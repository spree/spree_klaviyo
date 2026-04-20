module SpreeKlaviyo
  class CreateEvent < Base
    prepend ::Spree::ServiceModule::Base

    def call(klaviyo_integration:, event:, resource:, email:, guest_id: nil)
      klaviyo_integration.create_event(
        event: event,
        resource: resource,
        email: email,
        guest_id: guest_id
      )
    end
  end
end
