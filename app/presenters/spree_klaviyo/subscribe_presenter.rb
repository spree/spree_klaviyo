module SpreeKlaviyo
  class SubscribePresenter
    def initialize(email:, list_id:, type: 'profile-subscription-bulk-create-job')
      @email = email
      @list_id = list_id
      @type = type
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
                          "consent": 'SUBSCRIBED'
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
