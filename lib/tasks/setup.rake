namespace :spree_klaviyo do
  namespace :setup do
    desc 'Create klaviyo.subscribed metafield definition for Spree::NewsletterSubscriber'
    task create_metafield_definitions: :environment do
      SpreeKlaviyo::MetafieldMigration.ensure_klaviyo_subscribed_definition!
    end
  end
end
