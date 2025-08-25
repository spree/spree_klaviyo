module SpreeKlaviyo
  class SubscribePresenter
    SUBSCRIBED = 'SUBSCRIBED'.freeze
    UNSUBSCRIBED = 'UNSUBSCRIBED'.freeze

    def initialize(email:, list_id:, type: 'profile-subscription-bulk-create-job', subscribed: true, custom_properties: {})
      @email = email
      @list_id = list_id
      @type = type
      @subscribed = subscribed
      @custom_properties = custom_properties
    end

    def call
      {
        data: {
          type: @type,
          attributes: {
            profiles: {
              data: [
                {
                  "type": 'profile',
                  "attributes": {
                    email: @email,
                    "subscriptions": {
                      "email": {
                        "marketing": {
                          "consent": @subscribed ? SUBSCRIBED : UNSUBSCRIBED
                        }
                      }
                    }
                  }
                }
              ]
            }
          },
          relationships: {
            list: {
              data: {
                type: 'list',
                id: @list_id
              }
            }
          }
        }
      }
    end
  end
end
