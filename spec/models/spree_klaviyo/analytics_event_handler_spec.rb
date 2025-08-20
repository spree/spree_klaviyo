require 'spec_helper'

describe SpreeKlaviyo::AnalyticsEventHandler do
  include ActiveJob::TestHelper

  let(:store) { create(:store) }
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user) }
  let(:product) { create(:product) }
  let(:line_item) { create(:line_item, order: order) }
  let(:klaviyo_integration) { create(:klaviyo_integration, store: store) }

  subject { described_class.new }

  before do
    allow(subject).to receive(:store).and_return(store)
    allow(subject).to receive(:user).and_return(user)
    allow(subject).to receive(:identity_hash).and_return({ visitor_id: 'visitor_123' })

    # Stub the client method to return the klaviyo_integration
    allow(subject).to receive(:client).and_return(klaviyo_integration)

    # Stub configuration for async_tracking
    allow(SpreeKlaviyo::Config).to receive(:[]).with(:async_tracking).and_return(true)
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
          klaviyo_integration.id,
          'product_viewed',
          { email: user.email, guest_id: 'visitor_123' },
          { resource: product }
        )
      end

      it 'enqueues analytics event job for order_completed' do
        expect {
          subject.handle_event('order_completed', { order: order })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'order_completed',
          { email: order.email, guest_id: 'visitor_123' },
          { resource: order }
        )
      end

      it 'enqueues analytics event job for product_added' do
        expect {
          subject.handle_event('product_added', { line_item: line_item })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
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
        allow(subject).to receive(:user).and_return(nil)
        
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
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
          event: 'product_viewed',
          resource: product,
          email: user.email,
          guest_id: 'visitor_123'
        )
        subject.handle_event('product_viewed', { product: product })
      end

      it 'calls create_event directly for order_completed' do
        expect(klaviyo_integration).to receive(:create_event).with(
          event: 'order_completed',
          resource: order,
          email: order.email,
          guest_id: 'visitor_123'
        )
        subject.handle_event('order_completed', { order: order })
      end
    end

    context 'when no client is available' do
      before do
        allow(subject).to receive(:client).and_return(nil)
      end

      it 'returns early without processing' do
        expect {
          subject.handle_event('product_viewed', { product: product })
        }.not_to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob)
      end
    end

    context 'when both email and visitor_id are blank' do
      before do
        allow(subject).to receive(:user).and_return(nil)
        allow(subject).to receive(:identity_hash).and_return({ visitor_id: nil })
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
          subject.send(:enqueue_event, 'test_event', 'test_resource', 'test@example.com', 'visitor_123')
        }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob).with(
          klaviyo_integration.id,
          'test_event',
          { email: 'test@example.com', guest_id: 'visitor_123' },
          { resource: 'test_resource' }
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
          event: 'test_event',
          resource: 'test_resource',
          email: 'test@example.com',
          guest_id: 'visitor_123'
        )
        subject.send(:track_event_sync, 'test_event', 'test_resource', 'test@example.com', 'visitor_123')
      end
    end
  end
end
