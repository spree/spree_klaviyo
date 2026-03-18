module SpreeKlaviyo
  class UserPresenter
    def initialize(email:, address: nil, user: nil, guest_id: nil)
      @email = email
      @address = address
      @user = user
      @guest_id = guest_id
    end

    def call
      {
        data: {
          type: 'profile',
          attributes: {
            anonymous_id: guest_id,
            email: email
          }.merge!(address_attributes, user_attributes)
        }.merge!(try_klaviyo_id)
      }
    end

    private

    attr_reader :email, :address, :user, :guest_id

    def user_attributes
      return {} if user.nil?

      {
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        external_id: klaviyo_external_id
      }
    end

    def klaviyo_external_id
      user.id
    end

    def address_attributes
      return {} if address.nil?

      {
        first_name: address.first_name,
        last_name: address.last_name,
        location: {
          address1: address.address1,
          address2: address.address2,
          city: address.city,
          country: address.country_name,
          region: address.state_text,
          zip: address.zipcode
        }
      }
    end

    def try_klaviyo_id
      return {} if user.nil? || user.klaviyo_id.blank?

      { id: user.klaviyo_id }
    end
  end
end
