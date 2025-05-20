module SpreeKlaviyo
  module ShipmentHandlerDecorator
    def perform
      super
      track_package_shipped_event
    end

    def track_package_shipped_event
      order = @shipment.order

      analytics_event_handlers = ::Spree::Analytics.event_handlers.map do |handler|
        handler.new(user: order.user, session: nil, request: nil, store: order.store)
      end

      analytics_event_handlers.each do |handler|
        handler.handle_event('package_shipped', { order: order, shipment: @shipment })
      end
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
