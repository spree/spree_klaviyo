Rails.application.config.after_initialize do
  Rails.application.config.spree.integrations << Spree::Integrations::Klaviyo
  Rails.application.config.spree.analytics_event_handlers << SpreeKlaviyo::AnalyticsEventHandler

  # Register event subscribers
  Spree.subscribers << SpreeKlaviyo::OrderSubscriber
  Spree.subscribers << SpreeKlaviyo::KlaviyoNewsletterSubscriber
  Spree.subscribers << SpreeKlaviyo::ShipmentSubscriber
  Spree.subscribers << SpreeKlaviyo::KlaviyoProfileSubscriber
end
