module SpreeKlaviyo
  class AddressPresenter
    def initialize(address:)
      @address = address
    end

    def call
      return {} if @address.nil?

      {
        city: @address.city,
        country: @address.country_name,
        postalCode: @address.zipcode,
        state: @address.state_text,
        street: @address.street,
        phone: @address.phone,
        name: @address.full_name,
        first_name: @address.first_name,
        last_name: @address.last_name
      }
    end

    private

    attr_reader :address
  end
end
