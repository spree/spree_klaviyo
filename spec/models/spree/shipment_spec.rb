require 'spec_helper'

describe Spree::Shipment, type: :model do
  let!(:order) { create(:order, number: 'S12345', store: store) }
  let(:store) { Spree::Store.default }
  let(:shipment) do
    create(:shipment, number: 'H21265865494', cost: 1, state: 'pending', stock_location: create(:stock_location), order: order)
  end
  let!(:klaviyo_integration) { create(:klaviyo_integration, store: order.store) }

  describe '#ship' do
    %w[ready canceled].each do |state|
      context "from #{state}" do
        before do
          allow(order).to receive(:update_with_updater!)
          allow(shipment).to receive_messages(require_inventory: false, update_order: true, state: state)
        end

        it 'tracks package shipped event' do
          expect_any_instance_of(Spree::Integrations::Klaviyo).to receive(:create_event)
            .with(event: 'Package Shipped', resource: shipment, email: order.email)

          shipment.ship!
        end
      end
    end
  end
end
