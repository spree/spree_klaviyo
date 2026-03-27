module SpreeKlaviyo
  module PublishableDecorator
    def event_payload
      payload = super
      vid = SpreeKlaviyo::Current.visitor_id
      return payload if vid.blank?

      payload.stringify_keys.merge('visitor_id' => vid)
    end
  end
end

Spree::Publishable.prepend(SpreeKlaviyo::PublishableDecorator)
