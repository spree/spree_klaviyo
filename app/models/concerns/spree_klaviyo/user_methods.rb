module SpreeKlaviyo
  module UserMethods
    extend ActiveSupport::Concern

    included do
      store_accessor :private_metadata, :klaviyo_id
      store_accessor :private_metadata, :klaviyo_subscribed
    end

    def klaviyo_subscribed?
      klaviyo_subscribed.to_b
    end

    def create_or_update_klaviyo_profile(klaviyo_integration:, guest_id: nil)
      SpreeKlaviyo::CreateOrUpdateProfileJob.perform_later(klaviyo_integration.id, id, guest_id)
    rescue RedisClient::CannotConnectError, Redis::CannotConnectError, Redis::TimeoutError, Redis::CommandError => e
      Rails.error.report(e, context: { user_id: id }, source: 'spree.klaviyo')
    end

    def fetch_klaviyo_profile(klaviyo_integration:)
      return if klaviyo_id.present?

      SpreeKlaviyo::FetchProfileJob.perform_later(klaviyo_integration.id, id)
    rescue RedisClient::CannotConnectError, Redis::CannotConnectError, Redis::TimeoutError, Redis::CommandError => e
      Rails.error.report(e, context: { user_id: id }, source: 'spree.klaviyo')
    end
  end
end
