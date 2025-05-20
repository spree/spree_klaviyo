module SpreeKlaviyo
  class LineItemPresenter < ProductPresenter
    include ::Spree::BaseHelper
    include ::Spree::ProductsHelper

    def initialize(resource:, quantity:, total_price:, currency:, store:, position: nil)
      @resource = resource
      @position = position
      @quantity = quantity
      @total_price = total_price
      super(product: resource&.product, store: store)
    end

    def call
      return {} if @resource.nil?

      super.merge({
                    quantity: @quantity,
                    item_price: @resource.price,
                    row_total: @total_price
                  })
    end

    private

    attr_reader :resource, :quantity, :total_price, :currency, :position, :current_store, :feeable_item_ids
  end
end
