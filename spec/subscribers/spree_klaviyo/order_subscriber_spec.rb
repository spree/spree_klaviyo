require 'spec_helper'

RSpec.describe SpreeKlaviyo::OrderSubscriber do
  describe '#handle_order_completed_event' do
    let(:order) { create(:completed_order_with_totals) }
    let!(:klaviyo_integration) { create(:klaviyo_integration, store: order.store) }
    let(:event) { Spree::Event.new(name: 'order.completed', payload: order.event_payload, store_id: order.store_id) }

    context 'when order belongs to a guest user' do
      before { order.update_column(:user_id, nil) }

      it 'enqueues CreateGuestProfileJob' do
        expect(SpreeKlaviyo::CreateGuestProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, order.id)

        described_class.new.call(event)
      end
    end

    context 'when order belongs to a registered user' do
      it 'does not enqueue CreateGuestProfileJob' do
        expect(SpreeKlaviyo::CreateGuestProfileJob).not_to receive(:perform_later)

        described_class.new.call(event)
      end
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue CreateGuestProfileJob' do
        expect(SpreeKlaviyo::CreateGuestProfileJob).not_to receive(:perform_later)

        described_class.new.call(event)
      end
    end
  end

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
