module SpreeKlaviyo
  class UserPresenter
    def initialize(email: nil, address: nil, user: nil, guest_id: nil)
      @user = user
      @email = email || user&.email
      @address = address || user&.bill_address
      @guest_id = guest_id
    end

    def call
      {
        data: {
          type: 'profile',
          attributes: {
            anonymous_id: guest_id,
            email: email,
            first_name: first_name,
            last_name: last_name,
            external_id: klaviyo_external_id,
            location: {
              address1: address&.address1,
              address2: address&.address2,
              city: address&.city,
              country: address&.country_name,
              region: address&.state_text,
              zip: address&.zipcode
            }
          }
        }.merge!(try_klaviyo_id)
      }
    end

    private

    attr_reader :email, :address, :user, :guest_id

    def first_name
      user&.first_name || address&.first_name
    end

    def last_name
      user&.last_name || address&.last_name
    end

    def klaviyo_external_id
      user.id
    end

    def try_klaviyo_id
      return {} if user.nil? || user.klaviyo_id.blank?

      { id: user.klaviyo_id }
    end
  end
end
