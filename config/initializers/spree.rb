Rails.application.config.after_initialize do
  Rails.application.config.spree.integrations << Spree::Integrations::Klaviyo
  Rails.application.config.spree.analytics_event_handlers << SpreeKlaviyo::AnalyticsEventHandler
  Rails.application.config.spree.analytics_events[:order_canceled] = 'Order Cancelled'
end
