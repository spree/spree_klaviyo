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
      body = {
        data: {
          type: 'profile',
          attributes: attributes
        }
      }

      if @user&.klaviyo_id.present?
        body[:data][:id] = @user.klaviyo_id
      end

      body
    end

    private

    def attributes
      location = {
        address1: @address&.address1,
        address2: @address&.address2,
        city:     @address&.city,
        country:  @address&.country_name,
        region:   @address&.state_text,
        zip:      @address&.zipcode
      }.compact
    
      attrs = {
        email:       @user.present? ? @user.email : @email,
        first_name:  @user&.first_name || @address&.first_name,
        last_name:   @user&.last_name  || @address&.last_name,
        external_id: @user&.id
      }.compact
    
      attrs[:anonymous_id] = @guest_id if @guest_id.present?
      attrs[:location] = location unless location.empty?
      attrs[:properties] = @custom_properties unless @custom_properties.empty?
      attrs
    end
  end
end
