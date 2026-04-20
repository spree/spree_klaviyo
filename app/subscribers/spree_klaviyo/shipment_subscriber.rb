module SpreeKlaviyo
  class ShipmentSubscriber < Spree::Subscriber
    subscribes_to 'shipment.shipped'

    on 'shipment.shipped', :handle_shipment_shipped

    private

    def handle_shipment_shipped(event)
      shipment_id = event.payload['id']
      return unless shipment_id

      shipment = Spree::Shipment.find_by_param(shipment_id)
      return unless shipment

      order = shipment.order
      integration = Spree::Integrations::Klaviyo.find_by(store_id: order.store_id)
      return if integration.blank?

      SpreeKlaviyo::AnalyticsEventJob.perform_later(
        integration.id, 'Package Shipped', Spree::Shipment.name, shipment.id, order.email
      )
    end
  end
end
