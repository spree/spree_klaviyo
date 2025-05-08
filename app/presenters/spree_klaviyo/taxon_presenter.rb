module SpreeKlaviyo
  class TaxonPresenter
    include Spree::BaseHelper
    include ::Spree::ImagesHelper
    include Rails.application.routes.mounted_helpers

    def initialize(taxon:)
      @taxon = taxon
    end

    def call
      {
        name: @taxon.pretty_name,
        image_url: @taxon.image.present? ? spree_image_url(@taxon.image, width: 1200, height: 1200) : '',
        url: spree_storefront_resource_url(@taxon, store: @taxon.store)
      }
    end
  end
end
