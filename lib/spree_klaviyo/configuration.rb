module SpreeKlaviyo
  class Configuration
    class << self
      def klaviyo_api_url
        ENV.fetch('KLAVIYO_API_URL', 'https://a.klaviyo.com/api/')
      end

      def klaviyo_api_revision
        ENV.fetch('KLAVIYO_API_REVISION', '2025-04-15')
      end

      def klaviyo_api_open_timeout
        ENV.fetch('KLAVIYO_API_OPEN_TIMEOUT', 10).to_i
      end

      def klaviyo_api_read_timeout
        ENV.fetch('KLAVIYO_API_READ_TIMEOUT', 10).to_i
      end
    end
  end
end
