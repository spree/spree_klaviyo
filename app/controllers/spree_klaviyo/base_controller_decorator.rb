module SpreeKlaviyo
  module BaseControllerDecorator
    def self.prepended(base)
      base.before_action :set_spree_klaviyo_current_visitor
    end

    private

    def set_spree_klaviyo_current_visitor
      SpreeKlaviyo::Current.visitor_id = set_visitor_id_for_spree_klaviyo
    end

    def set_visitor_id_for_spree_klaviyo
      if respond_to?(:visitor_id, true)
        visitor_id
      else
        session[:spree_visitor_token] ||= SecureRandom.uuid
      end
    end
  end
end

# Only activate when the storefront engine is loaded (Spree::StoreController is defined).
# We prepend BaseController (not StoreController) because Devise controllers inherit from
# BaseController directly and would otherwise miss the visitor_id setup.
if defined?(Spree::StoreController)
  Spree::BaseController.prepend(SpreeKlaviyo::BaseControllerDecorator)
end
