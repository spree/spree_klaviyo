module SpreeKlaviyo
  class ReimbursementPresenter
    include ::Spree::BaseHelper
    include ::Spree::ImagesHelper
    include Rails.application.routes.mounted_helpers

    def initialize(reimbursement:, store: nil)
      @reimbursement = reimbursement
      @order = reimbursement.order
      @current_store = store || reimbursement.store || @order.store
    end

    def call
      {
        customer_name: @order.name || ::Spree.t('customer'),
        email: @order&.user&.email || @order.email,
        order_number: @order.number,
        store_name: @current_store.name,
        total: @reimbursement.total.to_f,
        display_total: @reimbursement.display_total.to_s,
        number: @reimbursement.number,
        reimbursement_id: @reimbursement.id,
        return_items: return_items,
        exchange_items: exchange_items
      }
    end

    private

    def return_items
      @reimbursement.return_items.map do |return_item|
        variant = return_item.variant
        {
          name: variant.name,
          sku: variant.sku,
          variant: variant.options_text,
          image_url: variant_image(variant),
          url: respond_to?(:spree_storefront_resource_url) ? spree_storefront_resource_url(variant.product, store: @current_store) : nil
        }
      end
    end

    def variant_image(variant)
      image = variant.primary_media
      image.present? && image.attached? ? spree_image_url(image, variant: :mini) : ''
    end

    def exchange_items
      @reimbursement.return_items.exchange_requested.map do |return_item|
        exchange_variant = return_item.exchange_variant
        {
          name: exchange_variant.name,
          sku: exchange_variant.sku,
          variant: exchange_variant.options_text,
          image_url: variant_image(exchange_variant),
          url: respond_to?(:spree_storefront_resource_url) ? spree_storefront_resource_url(exchange_variant.product, store: @current_store) : nil
        }
      end
    end
  end
end
