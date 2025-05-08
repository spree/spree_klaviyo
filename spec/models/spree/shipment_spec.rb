require 'spec_helper'

describe Spree::Shipment, type: :model do
  let!(:order) { create(:order, number: 'S12345', store: store) }
  let(:store) { Spree::Store.default }
  let(:shipment) do
    create(:shipment, number: 'H21265865494', cost: 1, state: 'pending', stock_location: create(:stock_location), order: order)
  end

  describe '#ship' do
    %w[ready canceled].each do |state|
      context "from #{state}" do
        before do
          allow(order).to receive(:update_with_updater!)
          allow(shipment).to receive_messages(require_inventory: false, update_order: true, state: state)
        end

        it 'tracks package shipped event' do
          analytics_event_handler = double
          allow(Spree::Analytics).to receive(:event_handlers).and_return([analytics_event_handler])
          allow(analytics_event_handler).to receive(:new).and_return(analytics_event_handler)
          expect(analytics_event_handler).to receive(:handle_event).with('package_shipped', { order: order, shipment: shipment })

          shipment.ship!
        end
      end
    end
  end
end
