module SpreeKlaviyo
  class UserPresenter
    def initialize(email:, address: nil, user: nil, guest_id: nil, custom_properties: {})
      @email = email
      @address = address
      @user = user
      @guest_id = guest_id
      @custom_properties = custom_properties || {}
    end

    def call
      {
        data: {
          type: 'profile',
          attributes: attributes
        }
      }.merge(try_klaviyo_id)
    end

    private

    def try_klaviyo_id
      @user&.klaviyo_id.present? ? { id: @user.klaviyo_id } : {}
    end

    def attributes
      base = {
        anonymous_id: @guest_id,
        email: @user.present? ? @user.email : @email,
        first_name: @user&.first_name || @address&.first_name,
        last_name: @user&.last_name || @address&.last_name,
        external_id: @user&.id,
        location: {
          address1: @address&.address1,
          address2: @address&.address2,
          city: @address&.city,
          country: @address&.country_name,
          region: @address&.state_text,
          zip: @address&.zipcode
        }
      }

      return base if @custom_properties.empty?

      base.merge(properties: @custom_properties)
    end
  end
end
