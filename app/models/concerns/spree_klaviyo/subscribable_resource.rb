module SpreeKlaviyo
  module SubscribableResource
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

    def subscribe_to_klaviyo
      klaviyo_integration = store_integration('klaviyo')
      return unless klaviyo_integration

      SpreeKlaviyo::SubscribeJob.perform_later(klaviyo_integration.id, email)
    end
  end
end
