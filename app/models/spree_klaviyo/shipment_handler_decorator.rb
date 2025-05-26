module SpreeKlaviyo
  module ShipmentHandlerDecorator
    def perform
      super
      track_package_shipped_event
    end

    def track_package_shipped_event
      order = @shipment.order

      klaviyo_integration = order.store.integrations.active.find_by(type: 'Spree::Integrations::Klaviyo')
      return if klaviyo_integration.blank?

      klaviyo_integration.create_event(event: 'Package Shipped', resource: @shipment, email: order.email)
    rescue StandardError => e
      Rails.error.report(
        e,
        context: { event_name: 'package_shipped', record: { order: order, shipment: @shipment } },
        source: 'spree.core'
      )
    end
  end

  ::Spree::ShipmentHandler.prepend(ShipmentHandlerDecorator)
end
