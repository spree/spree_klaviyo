module SpreeKlaviyo
  module BaseControllerDecorator
    def self.prepended(base)
      base.before_action :set_spree_klaviyo_visitor_current
    end

    private

    def set_spree_klaviyo_visitor_current
      SpreeKlaviyo::Current.visitor_id = resolve_visitor_id_for_klaviyo_current
    end

    # Devise (e.g. sign up) inherits Spree::BaseController, not Spree::StoreController, so we cannot
    # rely on StoreController's AnalyticsHelper alone. Match storefront session token when needed.
    def resolve_visitor_id_for_klaviyo_current
      if respond_to?(:visitor_id, true)
        visitor_id
      else
        session[:spree_visitor_token] ||= SecureRandom.uuid
      end
    end
  end
end

if defined?(Spree::StoreController)
  Spree::BaseController.prepend(SpreeKlaviyo::BaseControllerDecorator)
end
