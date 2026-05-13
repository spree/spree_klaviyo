require 'spec_helper'

RSpec.describe SpreeKlaviyo::ReimbursementSubscriber do
  describe '#handle_reimbursement_reimbursed' do
    let(:reimbursement) { create(:reimbursement) }
    let(:order) { reimbursement.order }
    let!(:klaviyo_integration) { create(:klaviyo_integration, store: order.store) }
    let(:event) { Spree::Event.new(name: 'reimbursement.reimbursed', payload: { 'id' => reimbursement.prefixed_id }, store_id: order.store_id) }

    it 'enqueues AnalyticsEventJob' do
      expect(SpreeKlaviyo::AnalyticsEventJob).to receive(:perform_later)
        .with(klaviyo_integration.id, 'Reimbursement Paid', 'Spree::Reimbursement', reimbursement.id, order.email)

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
