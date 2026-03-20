module SpreeKlaviyo
  # Default credentials for tests and VCR — keep in sync with +filter_sensitive_data+ placeholders.
  module Testing
    module_function

    def default_newsletter_list_id
      ENV.fetch('KLAVIYO_DEFAULT_NEWSLETTER_LIST_ID', '1234')
    end

    def default_public_api_key
      ENV.fetch('KLAVIYO_PUBLIC_API_KEY', '1234')
    end

    def default_private_api_key
      ENV.fetch('KLAVIYO_PRIVATE_API_KEY', '1234567899')
    end
  end
end
