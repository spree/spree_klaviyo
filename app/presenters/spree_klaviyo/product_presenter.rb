module SpreeKlaviyo
  class ProductPresenter
    include ::Spree::BaseHelper
    include ::Spree::ImagesHelper
    include Rails.application.routes.mounted_helpers

    def initialize(product:, store:)
      @product = product
      @current_store = store
      @current_currency = store.default_currency
    end

    def call
      return {} if @product.nil?

      {
        name: @product.name,
        price: @product.amount_in(current_currency)&.to_f,
        brand: @product&.brand_name,
        category: @product.main_taxon&.pretty_name,
        currency: current_currency,
        url: spree_storefront_resource_url(@product, store: @store),
        image_url: @product.default_image.present? ? spree_image_url(@product.default_image, width: 1200, height: 1200) : '',
        sku: @product.sku
      }
    end

    private

    attr_reader :current_store, :current_currency
  end
end
