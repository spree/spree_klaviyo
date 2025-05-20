module SpreeKlaviyo
  class ShipmentPresenter < OrderPresenter
    include ::Spree::BaseHelper
    include ::Spree::ProductsHelper
    include ::Spree::ImagesHelper
    include Rails.application.routes.mounted_helpers

    def initialize(shipment:, order: nil, store: nil)
      @shipment = shipment
      @order = order || shipment.order
      @current_store = store || order.store || shipment.store
    end

    def call
      {
        customer_name: @order.name || ::Spree.t('customer'),
        email: @order&.user&.email || @order.email,
        order_number: @order.number,
        shipping_method: shipping_method_name(@shipment),
        tracking: @shipment&.tracking.to_s,
        tracking_url: @shipment&.tracking_url,
        store_name: @current_store.name,
        cost: @shipment.final_price.to_f,
        completed_at: @order.completed_at&.iso8601.to_s,
        shipped_items: shipped_items,
        bill_address: AddressPresenter.new(address: @order.bill_address).call,
        ship_address: AddressPresenter.new(address: @order.ship_address).call
      }
    end

    private

    attr_reader :order, :shipment, :current_store

    def shipped_items
      @shipment.manifest.map do |shipped_item|
        shipped_items_quantity = shipped_item.line_item.quantity
        {
          url: spree_storefront_resource_url(shipped_item.variant.product),
          image_url: shipped_item.variant.default_image.present? ? spree_image_url(shipped_item.variant.default_image, width: 1200, height: 1200) : '',
          name: shipped_item.variant.name,
          variant: shipped_item.variant.options_text,
          sku: shipped_item.variant.sku,
          shipped_quantity: shipped_item.quantity,
          total_quantity: shipped_items_quantity,
          price: shipped_item.line_item.price.to_f,
          total_price: shipped_item.line_item.amount.to_f,
          brand: brand_name(shipped_item.variant.product)
        }.merge(try_variants(shipped_item.variant))
      end
    end
  end
end
