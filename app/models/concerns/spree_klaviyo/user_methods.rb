module SpreeKlaviyo
  module UserMethods
    extend ActiveSupport::Concern

    included do
      store_accessor :private_metadata, :klaviyo_id
      store_accessor :private_metadata, :klaviyo_subscribed

      after_commit :subscribe_to_klaviyo, on: :update, if: :marketing_opt_in_changed?
    end

    def klaviyo_subscribed?
      klaviyo_subscribed.to_b
    end

    def create_or_update_klaviyo_profile(klaviyo_integration:, guest_id: nil)
      SpreeKlaviyo::CreateOrUpdateProfileJob.perform_later(klaviyo_integration.id, id, guest_id)
    end

    def fetch_klaviyo_profile(klaviyo_integration:)
      return if klaviyo_id.present?

      SpreeKlaviyo::FetchProfileJob.perform_later(klaviyo_integration.id, id)
    end

    private

    def marketing_opt_in_changed?
      return false if klaviyo_subscribed?

      Spree::Deprecation.warn('`SpreeKlaviyo::UserMethods#marketing_opt_in_changed?` is deprecated and will be removed in SpreeKlaviyo 1.1.0. ' \
        'Use `SpreeKlaviyo::OrderDecorator#subscribe_user_to_klaviyo_newsletter` or `SpreeKlaviyo::AnalyticsEventHandler#handle_event` instead.')
      saved_change_to_accepts_email_marketing? && accepts_email_marketing?
    end

    def subscribe_to_klaviyo
      Spree::Deprecation.warn('`SpreeKlaviyo::UserMethods#subscribe_to_klaviyo` is deprecated and will be removed in SpreeKlaviyo 1.1.0. ' \
        'Use `SpreeKlaviyo::OrderDecorator#subscribe_user_to_klaviyo_newsletter` or `SpreeKlaviyo::AnalyticsEventHandler#handle_event` instead.')
      klaviyo_integration = store_integration('klaviyo')
      return unless klaviyo_integration

      SpreeKlaviyo::SubscribeJob.perform_later(klaviyo_integration.id, email, id)
    end
  end
end
