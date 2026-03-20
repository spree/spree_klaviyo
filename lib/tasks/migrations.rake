namespace :spree_klaviyo do
  namespace :migrations do
    desc 'Create klaviyo.subscribed metafield definition for Spree::NewsletterSubscriber'
    task migrate_klaviyo_subscribed_metafield: :environment do
      SpreeKlaviyo::MetafieldMigration.ensure_klaviyo_subscribed_definition!
    end
  end
end
