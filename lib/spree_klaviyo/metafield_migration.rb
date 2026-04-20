module SpreeKlaviyo
  module MetafieldMigration
    module_function

    def ensure_klaviyo_subscribed_definition!
      boolean_type = Spree.metafields.types.find { |t| t.name.demodulize == 'Boolean' }
      raise 'Spree metafields Boolean type is not registered' unless boolean_type

      Spree::MetafieldDefinition.find_or_create_by!(
        namespace: 'klaviyo',
        key: 'subscribed',
        resource_type: 'Spree::NewsletterSubscriber'
      ) do |definition|
        definition.name = 'Klaviyo subscribed'
        definition.metafield_type = boolean_type.to_s
        definition.description = 'Whether the subscriber is subscribed to the newsletter in Klaviyo' if definition.respond_to?(:description=)
      end
    end
  end
end
