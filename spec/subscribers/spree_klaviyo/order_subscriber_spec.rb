require 'spec_helper'

RSpec.describe SpreeKlaviyo::OrderSubscriber do
  describe '#track_order_cancelled_event' do
    let(:order) { create(:completed_order_with_totals) }
    let!(:klaviyo_integration) { create(:klaviyo_integration, store: order.store) }
    let(:event) { Spree::Event.new(name: 'order.canceled', payload: order.event_payload, store_id: order.store_id) }

    it 'enqueues AnalyticsEventJob' do
      expect(SpreeKlaviyo::AnalyticsEventJob).to receive(:perform_later)
        .with(klaviyo_integration.id, 'Order Cancelled', 'Spree::Order', order.id, order.email)

      described_class.new.call(event)
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue job' do
        expect(SpreeKlaviyo::AnalyticsEventJob).not_to receive(:perform_later)
        described_class.new.call(event)
      end
    end
  end
end
