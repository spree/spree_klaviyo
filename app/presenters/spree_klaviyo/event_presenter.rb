module SpreeKlaviyo
  class EventPresenter
    def initialize(integration:, event:, resource:, email:, guest_id: nil)
      @integration = integration
      @store = integration.store
      @resource = resource
      @event = event
      @email = email
      @guest_id = guest_id
    end

    def call
      {
        data: {
          type: 'event',
          attributes: {
            properties: properties,
            metric: {
              data: {
                type: 'metric',
                attributes: {
                  name: @event
                }
              }
            },
            profile: @email.present? ? profile : guest_profile,
            **top_level_attributes
          }
        }
      }
    end

    private

    def top_level_attributes
      if @resource.is_a?(::Spree::Order)
        OrderAttributesPresenter.new(event_name: @event, order: @resource).call
      else
        {}
      end
    end

    def properties
      if @resource.is_a? ::Spree::Order
        OrderPresenter.new(order: @resource).call
      elsif @resource.is_a? ::Spree::Shipment
        ShipmentPresenter.new(shipment: @resource, store: @store).call
      elsif @resource.is_a? ::Spree::Product
        ProductPresenter.new(product: @resource, store: @store).call
      elsif @resource.is_a? ::Spree::Taxon
        TaxonPresenter.new(taxon: @resource).call
      elsif @resource.is_a? String
        {
          query: @resource
        }
      else
        {}
      end
    end

    def profile
      if @resource.is_a?(::Spree::Order) && events_that_update_profile.include?(@event)
        UserPresenter.new(
          email: @email,
          address: @resource&.bill_address || @resource&.ship_address,
          user: @resource&.user,
          guest_id: @guest_id
        ).call
      else
        {
          data: {
            type: 'profile',
            attributes: {
              anonymous_id: @guest_id,
              email: @email
            }
          }
        }
      end
    end

    def guest_profile
      {
        data: {
          type: 'profile',
          attributes: {
            anonymous_id: @guest_id
          }
        }
      }
    end

    def events_that_update_profile
      @events_that_update_profile ||= [::Spree::Analytics.events[:checkout_email_entered], ::Spree::Analytics.events[:order_completed]]
    end
  end
end
