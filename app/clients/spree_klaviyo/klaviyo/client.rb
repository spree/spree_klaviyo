module SpreeKlaviyo
  module Klaviyo
    class Client
      class Result < ::Spree::ServiceModule::Result; end

      def initialize(public_api_key:, private_api_key:)
        @public_api_key = public_api_key
        @private_api_key = private_api_key
      end

      def get_request(api_endpoint)
        request = Net::HTTP::Get.new(url(api_endpoint))
        request["accept"] = "application/json"
        request["revision"] = SpreeKlaviyo::Configuration.klaviyo_api_revision
        request["Authorization"] = "Klaviyo-API-Key #{private_api_key}"

        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          Result.new(true, response.read_body)
        else
          Result.new(false, response.read_body)
        end
      end

      def post_request(api_endpoint, body)
        request = Net::HTTP::Post.new(url(api_endpoint))
        request["accept"] = "application/json"
        request["revision"] = SpreeKlaviyo::Configuration.klaviyo_api_revision
        request["content-type"] = "application/json"
        request["Authorization"] = "Klaviyo-API-Key #{private_api_key}"
        request.body = body.to_json

        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          Result.new(true, response.read_body)
        else
          Result.new(false, response.read_body)
        end
      end

      def patch_request(api_endpoint, body)
        request = Net::HTTP::Patch.new(url(api_endpoint))
        request["accept"] = "application/json"
        request["revision"] = SpreeKlaviyo::Configuration.klaviyo_api_revision
        request["content-type"] = "application/json"
        request["Authorization"] = "Klaviyo-API-Key #{private_api_key}"
        request.body = body.to_json

        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          Result.new(true, response.read_body)
        else
          Result.new(false, response.read_body)
        end
      end

      private

      attr_reader :public_api_key, :private_api_key

      def url(endpoint = "")
        @url ||= URI.join(SpreeKlaviyo::Configuration.klaviyo_api_url, endpoint)
      end

      def http
        @http ||= Net::HTTP.new(url.host, url.port).tap do |net_http_instance|
          net_http_instance.use_ssl = true
          net_http_instance.open_timeout = SpreeKlaviyo::Configuration.klaviyo_api_open_timeout
          net_http_instance.read_timeout = SpreeKlaviyo::Configuration.klaviyo_api_read_timeout
        end
      end
    end
  end
end
