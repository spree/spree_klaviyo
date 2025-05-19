RSpec.describe SpreeKlaviyo::OrderAttributesPresenter do
  subject { described_class.new(event_name: event_name, order: order).call }

  let(:order) { create(:completed_order_with_totals) }

  context 'for a completed order' do
    let(:event_name) { 'Order Completed' }

    it 'builds top-level attributes' do
      expect(subject).to eq(
        value: order.total.to_f,
        time: order.completed_at.iso8601
      )
    end
  end

  context 'for a canceled order' do
    let(:event_name) { 'Order Cancelled' }
    let(:canceled_at) { DateTime.parse('02-01-2023T09:15:22Z') }

    before do
      order.update!(state: 'canceled', canceled_at: canceled_at)
    end

    it 'builds top-level attributes' do
      expect(subject).to eq(
        value: order.total.to_f,
        time: order.canceled_at.iso8601
      )
    end
  end
end
