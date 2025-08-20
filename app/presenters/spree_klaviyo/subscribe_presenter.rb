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
                  "attributes": profile_attributes
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

    private

    def profile_attributes
      attributes = {
        email: @email,
        "subscriptions": {
          "email": {
            "marketing": {
              "consent": @subscribed ? SUBSCRIBED : UNSUBSCRIBED
            }
          }
        }
      }

      if @custom_properties.present?
        @custom_properties.each do |key, value|
          if value.present?
            attributes[key] = value
          end
        end
      end

      attributes
    end
  end
end
