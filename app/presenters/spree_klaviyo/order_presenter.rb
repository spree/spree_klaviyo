module SpreeKlaviyo
  class OrderPresenter
    include Spree::BaseHelper
    include ::Spree::ImagesHelper

    def initialize(order:)
      @order = order
      @current_store = order.store
      @products = products(order)
    end

    def call
      {
        email: @order&.user&.email || @order.email,
        customer_name: @order.name || Spree.t('customer'),
        store_name: @current_store.name,
        order_id: @order.number,
        order_number: @order.number,
        affiliation: @order.store.name,
        value: subtotal,
        subtotal: subtotal,
        item_total: @order.item_total&.to_f,
        total: @order.total.to_f,
        revenue: @order.total&.to_f,
        shipping: @order.shipments.sum(&:cost).to_f,
        shipping_method: shipping_method_names,
        tax: @order.additional_tax_total&.to_f,
        included_tax: @order.included_tax_total&.to_f,
        discount: @order.promo_total&.to_f,
        items: products(@order),
        coupon: @order.coupon_code.to_s,
        currency: @order.currency,
        completed_at: @order.completed_at&.iso8601.to_s,
        checkout_url: Spree::Core::Engine.routes.url_helpers.checkout_url(host: @current_store.url_or_custom_domain, token: @order.token),
        all_adjustments: all_adjustments,
        bill_address: AddressPresenter.new(address: @order.bill_address).call,
        ship_address: AddressPresenter.new(address: @order.ship_address).call
      }.merge(try_shipped_shipments)
    end

    private

    attr_reader :order, :current_store

    def products(order)
      @products ||= order.line_items.includes(variant: { product: :taxons }).map.with_index do |line_item, index|
        LineItemPresenter.new(
          resource: line_item,
          quantity: line_item.quantity,
          total_price: line_item.amount,
          currency: order.currency,
          position: index + 1,
          store: order.store
        ).call
      end
    end

    def all_adjustments
      @order.all_adjustments.promotion.eligible.group_by(&:label).map do |label, adjustments|
        {
          label: label,
          amount: adjustments.sum(&:amount).to_f
        }
      end
    end

    def shipping_method_names
      @shipping_method_names ||= @order.shipments.map { |shipment| shipping_method_name(shipment) }.compact.uniq.join(',')
    end

    def shipping_method_name(shipment)
      shipment.shipping_method&.name.to_s
    end

    def try_shipped_shipments
      return {} unless @order.fully_shipped? && @order.shipments.shipped.any?

      {
        shipped_shipments: @order.shipments.shipped.map do |shipment|
          ShipmentPresenter.new(order: @order, shipment: shipment).call
        end
      }
    end

    def subtotal
      @order.analytics_subtotal
    end

    def try_variants(variant)
      {
        variant_dict: Spree::Variants::OptionsPresenter.new(variant).to_hash
      }
    end
  end
end
