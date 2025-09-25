require 'spec_helper'

describe SpreeKlaviyo::AnalyticsEventHandler do
  include ActiveJob::TestHelper

  let(:store) { create(:store) }
  let(:user) { create(:user, email: 'user@example.com') }
  let(:order) { create(:order, user: user, store: store, email: 'order@example.com') }
  let(:product) { create(:product, stores: [store]) }
  let(:taxon) { create(:taxon) }
  let(:line_item) { create(:line_item, order: order, product: product) }
  let!(:klaviyo_integration) { create(:klaviyo_integration, store: store, active: true) }

  subject do
    described_class.new(
      user: user,
      store: store,
      visitor_id: 'visitor_123'
    )
  end

  describe '#handle_event' do
    context 'with product events' do
      it 'enqueues analytics event job for product_viewed' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Product Viewed',
          product,
          user.email,
          'visitor_123'
        )
      end
    end

    context 'with cart events' do
      it 'enqueues analytics event job for product_added' do
        expect {
          subject.handle_event('product_added', { line_item: line_item })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Product Added',
          order,
          order.email,
          'visitor_123'
        )
      end
    end

    context 'with checkout events' do
      it 'enqueues analytics event job for checkout_started' do
        expect {
          subject.handle_event('checkout_started', { order: order })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Checkout Started',
          order,
          order.email,
          'visitor_123'
        )
      end

      it 'enqueues analytics event job for checkout_email_entered' do
        expect {
          subject.handle_event('checkout_email_entered', { order: order, email: 'new@example.com' })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Checkout Email Entered',
          order,
          'new@example.com',
          'visitor_123'
        )
      end
    end

    context 'with coupon events' do
      it 'enqueues analytics event job for coupon_entered' do
        expect {
          subject.handle_event('coupon_entered', { order: order })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Coupon Entered',
          order,
          order.email,
          'visitor_123'
        )
      end
    end

    context 'with order events' do
      it 'enqueues analytics event job for order_completed' do
        expect {
          subject.handle_event('order_completed', { order: order })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Order Completed',
          order,
          order.email,
          'visitor_123'
        )
      end
    end

    context 'with newsletter events' do

      let(:subscriber) { create(:newsletter_subscriber, email: 'test@example.com') }

      before do
        subscriber
      end

      context 'when subscriber not present' do
        let(:subscriber) { nil }

        it 'still enqueues subscribe job' do
          expect {
            subject.handle_event('subscribed_to_newsletter', { email: 'test@example.com' })
          }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(
            klaviyo_integration.id,
            'test@example.com'
          )
        end
      end

      it 'enqueues subscribe job for newsletter subscription' do
        expect {
          subject.handle_event('subscribed_to_newsletter', { email: 'test@example.com' })
        }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(
          klaviyo_integration.id,
          'test@example.com',
          subscriber.id,
          Spree::NewsletterSubscriber.to_s
        )
      end

      context 'when user is not present' do
        subject do
          described_class.new(
            user: nil,
            store: store,
            visitor_id: 'visitor_123'
          )
        end

        it 'uses provided email for newsletter subscription' do
          expect {
            subject.handle_event('subscribed_to_newsletter', { email: 'test@example.com' })
          }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(
            klaviyo_integration.id,
            'test@example.com',
            subscriber.id,
            Spree::NewsletterSubscriber.to_s
          )
        end
      end

      it 'also enqueues analytics event job for newsletter subscription' do
        expect {
          subject.handle_event('subscribed_to_newsletter', { email: 'test@example.com' })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Subscribed to Newsletter',
          nil,
          user.email,
          'visitor_123'
        )
      end

      it 'also enqueues analytics event job for newsletter unsubscription' do
        expect {
          subject.handle_event('unsubscribed_from_newsletter', { email: 'test@example.com' })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Unsubscribed from Newsletter',
          nil,
          user.email,
          'visitor_123'
        )
      end
    end

    context 'when user is not present' do
      subject do
        described_class.new(
          user: nil,
          store: store,
          visitor_id: 'visitor_123'
        )
      end

      it 'uses order email for product_added event' do
        expect {
          subject.handle_event('product_added', { line_item: line_item })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Product Added',
          order,
          order.email,
          'visitor_123'
        )
      end

      it 'uses nil email for product_viewed when no user' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'Product Viewed',
          product,
          nil,
          'visitor_123'
        )
      end
    end

    context 'when no client is available' do
      before do
        klaviyo_integration.update!(active: false)
      end

      it 'returns early without processing product events' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.not_to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob)
      end

      it 'returns early without processing newsletter events' do
        expect {
          subject.handle_event('subscribed_to_newsletter', { email: 'test@example.com' })
        }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
      end
    end

    context 'when both email and visitor_id are blank' do
      let!(:subscriber) { create(:newsletter_subscriber, email: 'test@example.com') }

      subject do
        described_class.new(
          user: nil,
          store: store,
          visitor_id: nil
        )
      end

      it 'returns early without processing product_viewed' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.not_to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob)
      end

      it 'still processes newsletter subscription (has explicit email)' do
        expect {
          subject.handle_event('subscribed_to_newsletter', { email: 'test@example.com' })
        }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
      end
    end
  end
end
