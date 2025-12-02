module Spree
  module Integrations
    class Klaviyo < Spree::Integration
      class Api::Error < StandardError; end

      NO_PROFILE_FOUND = 'No profile found'.freeze

      preference :klaviyo_public_api_key, :string
      preference :klaviyo_private_api_key, :password
      preference :default_newsletter_list_id, :string

      validates :preferred_klaviyo_public_api_key, :preferred_klaviyo_private_api_key, :preferred_default_newsletter_list_id, presence: true

      def self.integration_group
        'marketing'
      end

      def self.icon_path
        'integration_icons/klaviyo-logo.png'
      end

      def can_connect?
        # There's no method for checking if credentials are valid, but we can figure it out basing on response,
        # except Public API Key.
        result = client.get_request("lists/#{preferred_default_newsletter_list_id}")

        # 'Missing or invalid private key.' for invalid private key
        # 'A list with id #{id} does not exist.' for invalid newsletter list id
        @connection_error_message = JSON.parse(result.value)['errors'].first['detail'] if result.failure?

        result.success?
      end

      def create_profile(user, guest_id = nil)
        user_presenter = ::SpreeKlaviyo::UserPresenter.new(email: user.email, address: user&.bill_address, guest_id: guest_id)
        result = client.post_request('profiles/', user_presenter.call)

        handle_result(result)
      end

      def update_profile(user, guest_id = nil)
        user_presenter = ::SpreeKlaviyo::UserPresenter.new(email: user.email, address: user&.bill_address, user: user, guest_id: guest_id)
        result = client.patch_request("profiles/#{user.get_metafield('klaviyo.id').value}/", user_presenter.call)

        handle_result(result)
      end

      def subscribe_user(email)
        result = client.post_request(
          'profile-subscription-bulk-create-jobs/',
          ::SpreeKlaviyo::SubscribePresenter.new(email: email, list_id: preferred_default_newsletter_list_id).call
        )

        handle_result(result)
      end

      def unsubscribe_user(email)
        payload = ::SpreeKlaviyo::SubscribePresenter.new(
          email: email,
          list_id: preferred_default_newsletter_list_id,
          type: 'profile-subscription-bulk-delete-job',
          subscribed: false
        ).call

        result = client.post_request(
          'profile-subscription-bulk-delete-jobs/',
          payload
        )

        handle_result(result)
      end

      def create_back_in_stock_subscription(email:, variant_id:)
        body = ::SpreeKlaviyo::BackInStockSubscriptionPresenter.new(email: email, variant_id: variant_id).call
        result = client.post_request('back-in-stock-subscriptions/', body)

        handle_result(result)
      end

      def create_event(event:, resource:, email:, guest_id: nil)
        result = client.post_request(
          'events/',
          ::SpreeKlaviyo::EventPresenter.new(
            integration: self,
            event: event,
            resource: resource,
            email: email,
            guest_id: guest_id
          ).call
        )

        handle_result(result)
      end

      def fetch_profile(email:)
        result = client.get_request("profiles/?fields[profile]=email&filter=equals(email,'#{CGI.escapeURIComponent(email)}')")

        return Spree::ServiceModule::Result.new(false, email, NO_PROFILE_FOUND) if result.success? && JSON.parse(result.value)['data'].empty?

        handle_result(result)
      end

      private

      def client
        ::SpreeKlaviyo::Klaviyo::Client.new(
          public_api_key: preferred_klaviyo_public_api_key,
          private_api_key: preferred_klaviyo_private_api_key
        )
      end

      def handle_result(result)
        if result.success?
          Spree::ServiceModule::Result.new(true, result.value)
        else
          Rails.error.report(Api::Error.new(result.value), context: { integration_id: id }, source: 'spree.klaviyo')
          Spree::ServiceModule::Result.new(false, result.value)
        end
      end
    end
  end
end
