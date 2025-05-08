require 'spec_helper'

RSpec.describe Spree::Order, type: :model do
  describe 'after complete' do
    let(:order) { create(:order_with_totals, state: :payment) }

    context 'with accepted marketing' do
      let(:order) { create(:order_with_totals, state: :payment, accept_marketing: true) }

      context 'with klaviyo integration' do
        let!(:klaviyo_integration) { create(:klaviyo_integration) }

        it 'calls Klaviyo::SubscribeJob' do
          expect(SpreeKlaviyo::SubscribeJob).to receive(:perform_later).with(klaviyo_integration.id, order.email, order.user_id)
          order.next!
        end
      end
    end
  end

  describe 'after cancel' do
    let(:order) { create(:completed_order_with_totals) }
    let!(:payment) do
      create(
        :payment,
        order: order,
        amount: order.total,
        state: 'completed'
      )
    end

    it 'tracks order cancelled event' do
      analytics_event_handler = instance_double(SpreeKlaviyo::AnalyticsEventHandler)
      allow(SpreeKlaviyo::AnalyticsEventHandler).to receive(:new).and_return(analytics_event_handler)
      expect(analytics_event_handler).to receive(:handle_event).with('order_cancelled', { order: order })

      order.cancel
    end
  end
end
