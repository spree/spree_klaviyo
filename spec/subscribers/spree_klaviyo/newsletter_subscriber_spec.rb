require 'spec_helper'

RSpec.describe SpreeKlaviyo::NewsletterSubscriber do
  describe '#newsletter_subscriber.subscribed event' do
    # Spree invokes Spree::Subscriber#call (async via SubscriberJob); that delegates to #handle.
    subject(:invoke_subscriber) { described_class.new.call(event) }

    let(:store) { Spree::Store.default }
    let(:newsletter_subscriber) { create(:newsletter_subscriber) }
    let!(:klaviyo_integration) { create(:klaviyo_integration, store: store) }
    let(:event) do
      Spree::Event.new(
        name: 'newsletter_subscriber.subscribed',
        payload: { id: newsletter_subscriber.prefixed_id },
        store_id: store.id
      )
    end

    it 'enqueues SubscribeJob' do
      expect(SpreeKlaviyo::SubscribeJob).to receive(:perform_later).with(klaviyo_integration.id, newsletter_subscriber.id)
      invoke_subscriber
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue SubscribeJob' do
        expect(SpreeKlaviyo::SubscribeJob).not_to receive(:perform_later)
        invoke_subscriber
      end
    end
  end
end
