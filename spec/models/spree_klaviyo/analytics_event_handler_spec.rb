require 'spec_helper'

describe SpreeKlaviyo::AnalyticsEventHandler do
  include ActiveJob::TestHelper

  subject { described_class.new }

  let(:store) { create(:store) }
  let(:user) { create(:user) }
  let(:klaviyo_integration) { create(:klaviyo_integration, store: store) }
  let(:product) { create(:product) }
  let(:order) { create(:order, user: user, store: store) }
  let(:line_item) { create(:line_item, order: order, product: product) }

  before do
    allow(subject).to receive(:store).and_return(store)
    allow(subject).to receive(:user).and_return(user)
    allow(subject).to receive(:identity_hash).and_return({ visitor_id: 'visitor_123' })
    
    # Stub all configuration keys that might be accessed
    allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(true)
    allow(SpreeKlaviyo::Config).to receive(:[]).with(:async_tracking).and_return(true)
    allow(SpreeKlaviyo::Config).to receive(:[]).with(:job_queue).and_return('default')
  end

  describe '#handle_event' do
    context 'when async tracking is enabled' do
      before do
        allow(SpreeKlaviyo::Config).to receive(:[]).with(:async_tracking).and_return(true)
      end

      it 'enqueues analytics event job for product_viewed' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          'product_viewed',
          { email: user.email, guest_id: 'visitor_123' },
          { resource: product }
        )
      end

      it 'enqueues analytics event job for order_completed' do
        expect {
          subject.handle_event('order_completed', { order: order })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          'order_completed',
          { email: order.email, guest_id: 'visitor_123' },
          { resource: order }
        )
      end

      it 'enqueues analytics event job for product_added' do
        expect {
          subject.handle_event('product_added', { line_item: line_item })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          'product_added',
          { email: order.email, guest_id: 'visitor_123' },
          { resource: order }
        )
      end

      it 'enqueues subscribe job for newsletter subscription' do
        expect {
          subject.handle_event('subscribed_to_newsletter', { email: 'test@example.com' })
        }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(
          klaviyo_integration.id, 'test@example.com', user.id
        )
      end

      it 'enqueues unsubscribe job for newsletter unsubscription' do
        expect {
          subject.handle_event('unsubscribed_from_newsletter', { email: 'test@example.com' })
        }.to have_enqueued_job(SpreeKlaviyo::UnsubscribeJob).with(
          klaviyo_integration.id, 'test@example.com', user.id
        )
      end

      it 'handles events without email gracefully' do
        allow(user).to receive(:email).and_return(nil)
        allow(order).to receive(:email).and_return(nil)

        expect {
          subject.handle_event('product_viewed', { product: product })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          'product_viewed',
          { email: nil, guest_id: 'visitor_123' },
          { resource: product }
        )
      end
    end

    context 'when async tracking is disabled' do
      before do
        allow(SpreeKlaviyo::Config).to receive(:[]).with(:async_tracking).and_return(false)
        allow(subject).to receive(:client).and_return(klaviyo_integration)
        allow(klaviyo_integration).to receive(:create_event).and_return(Spree::ServiceModule::Result.new(true, 'success'))
      end

      it 'calls create_event directly for product_viewed' do
        expect(klaviyo_integration).to receive(:create_event).with(
          event: 'Product Viewed',
          resource: product,
          email: user.email,
          guest_id: 'visitor_123'
        )

        subject.handle_event('product_viewed', { product: product })
      end

      it 'calls create_event directly for order_completed' do
        expect(klaviyo_integration).to receive(:create_event).with(
          event: 'Order Completed',
          resource: order,
          email: order.email,
          guest_id: 'visitor_123'
        )

        subject.handle_event('order_completed', { order: order })
      end
    end

    context 'when no client is available' do
      before do
        allow(store.integrations.active).to receive(:find_by).and_return(nil)
      end

      it 'returns early without processing' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.not_to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob)

        expect {
          subject.handle_event('product_viewed', { product: product })
        }.not_to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob)
      end
    end

    context 'when both email and visitor_id are blank' do
      before do
        allow(user).to receive(:email).and_return(nil)
        allow(order).to receive(:email).and_return(nil)
        allow(subject).to receive(:identity_hash).and_return({ visitor_id: nil })
      end

      it 'returns early without processing' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.not_to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob)
      end
    end

    context 'when configuration is disabled' do
      before do
        allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(false)
      end

      it 'returns early without processing' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.not_to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob)
      end
    end
  end

  describe 'private methods' do
    describe '#enqueue_event' do
      it 'enqueues analytics event job with correct parameters' do
        expect {
          subject.send(:enqueue_event, 'test_event', product, 'test@example.com', 'visitor_456')
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          'test_event',
          { email: 'test@example.com', guest_id: 'visitor_456' },
          { resource: product }
        )
      end
    end

    describe '#track_event_sync' do
      before do
        allow(subject).to receive(:client).and_return(klaviyo_integration)
        allow(klaviyo_integration).to receive(:create_event).and_return(Spree::ServiceModule::Result.new(true, 'success'))
      end

      it 'calls create_event on client' do
        expect(klaviyo_integration).to receive(:create_event).with(
          event: 'Test Event',
          resource: product,
          email: 'test@example.com',
          guest_id: 'visitor_456'
        )

        subject.send(:track_event_sync, 'test_event', product, 'test@example.com', 'visitor_456')
      end

      it 'returns early when should_track_event? is false' do
        allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(false)

        expect(klaviyo_integration).not_to receive(:create_event)

        subject.send(:track_event_sync, 'test_event', product, 'test@example.com', 'visitor_456')
      end
    end

    describe '#should_track_event?' do
      it 'returns true when configuration is enabled' do
        allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(true)
        expect(subject.send(:should_track_event?)).to be true
      end

      it 'returns false when configuration is disabled' do
        allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(false)
        expect(subject.send(:should_track_event?)).to be false
      end
    end
  end
end
