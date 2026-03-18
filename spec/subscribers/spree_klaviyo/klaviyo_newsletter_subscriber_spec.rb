require 'spec_helper'

RSpec.describe SpreeKlaviyo::KlaviyoNewsletterSubscriber do
  describe '#subscribe_user_to_klaviyo_newsletter' do
    let(:order) { create(:order_with_totals, state: :complete, accept_marketing: true) }
    let!(:klaviyo_integration) { create(:klaviyo_integration, store: order.store) }
    let(:event) { Spree::Event.new(name: 'order.completed', payload: { id: order.id }, store_id: order.store_id) }

    it 'enqueues SubscribeJob' do
      expect(SpreeKlaviyo::SubscribeJob).to receive(:perform_later).with(klaviyo_integration.id, order.email, order.user_id)
      described_class.new.call(event)
    end

    context 'when accept_marketing is false' do
      let(:order) { create(:order_with_totals, state: :complete, accept_marketing: false) }

      it 'does not enqueue SubscribeJob' do
        expect(SpreeKlaviyo::SubscribeJob).not_to receive(:perform_later)
        described_class.new.call(event)
      end
    end

    context 'when user is already klaviyo subscribed' do
      before { order.user.update!(klaviyo_subscribed: true) }

      it 'does not enqueue SubscribeJob' do
        expect(SpreeKlaviyo::SubscribeJob).not_to receive(:perform_later)
        described_class.new.call(event)
      end
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue SubscribeJob' do
        expect(SpreeKlaviyo::SubscribeJob).not_to receive(:perform_later)
        described_class.new.call(event)
      end
    end
  end
end
