module SpreeKlaviyo
  class BackInStockSubscriptionPresenter
    def initialize(email:, variant_id:)
      @email = email
      @variant_id = variant_id
    end

    def call
      {
        data: {
          type: 'back-in-stock-subscription',
          attributes: {
            channels: %w[EMAIL],
            profile: {
              data: {
                type: 'profile',
                attributes: {
                  email: @email
                }
              }
            }
          },
          relationships: {
            variant: {
              data: {
                type: 'catalog-variant',
                id: "$custom:::$default:::#{@variant_id}"
              }
            }
          }
        }
      }
    end
  end
end
