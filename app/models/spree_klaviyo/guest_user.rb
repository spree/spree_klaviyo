module SpreeKlaviyo
  # A lightweight, non-persisted stand-in for Spree::User that exposes only the
  # attributes and methods required by Klaviyo presenters and services.
  #
  # It avoids the previous on-the-fly Struct monkey-patching and follows a clear
  # PORO pattern that is easier to test and extend.
  class GuestUser
    attr_accessor :email, :klaviyo_id, :id, :bill_address, :ship_address

    def initialize(email:, klaviyo_id: nil, id: nil, bill_address: nil, ship_address: nil)
      @email = email
      @klaviyo_id = klaviyo_id
      @id = id
      @bill_address = bill_address
      @ship_address = ship_address
    end

    # --------------------------------------------------------------------------
    # ActiveRecord-like API expected by downstream services
    # --------------------------------------------------------------------------
    def persisted?; false; end
    def update(*); true; end
    def update!(*); true; end
    def update_columns(*); true; end
    def reload; self; end
  end
end 