module SpreeKlaviyo
  module PublishableDecorator
    def event_payload
      payload = super
      return payload if SpreeKlaviyo::Current.visitor_id.blank?

      payload.stringify_keys.merge('visitor_id' => SpreeKlaviyo::Current.visitor_id)
    end
  end
end

Spree::Publishable.prepend(SpreeKlaviyo::PublishableDecorator)
