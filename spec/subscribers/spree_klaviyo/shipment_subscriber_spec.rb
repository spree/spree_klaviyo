require 'spec_helper'

RSpec.describe SpreeKlaviyo::ShipmentSubscriber do
  describe '#handle_shipment_shipped' do
    let(:store) { Spree::Store.default }
    let!(:order) { create(:order, number: 'S12345', store: store) }
    let(:shipment) do
      create(:shipment, number: 'H21265865494', cost: 1, state: 'pending', stock_location: create(:stock_location), order: order)
    end
    let!(:klaviyo_integration) { create(:klaviyo_integration, store: order.store) }
    let(:event) { Spree::Event.new(name: 'shipment.shipped', payload: { id: shipment.prefixed_id }, store_id: store.id) }

    it 'enqueues AnalyticsEventJob' do
      expect(SpreeKlaviyo::AnalyticsEventJob).to receive(:perform_later)
        .with(klaviyo_integration.id, 'Package Shipped', 'Spree::Shipment', shipment.id, order.email)

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
