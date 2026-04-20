require 'spec_helper'

RSpec.describe SpreeKlaviyo::NewsletterSubscriber do
  subject(:invoke_subscriber) { described_class.new.call(event) }
  let(:store) { Spree::Store.default }
  let(:newsletter_subscriber) { create(:newsletter_subscriber) }
  let!(:klaviyo_integration) { create(:klaviyo_integration, store: store) }

  describe '#newsletter_subscriber.created event' do
    let(:event) do
      Spree::Event.new(
        name: 'newsletter_subscriber.created',
        payload: newsletter_subscriber.event_payload,
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

  describe '#newsletter_subscriber.deleted event' do
    let(:event) do
      Spree::Event.new(
        name: 'newsletter_subscriber.deleted',
        payload: newsletter_subscriber.event_payload,
        store_id: store.id
      )
    end

    before do
      newsletter_subscriber.delete
    end

    it 'enqueues UnsubscribeJob' do
      expect(SpreeKlaviyo::UnsubscribeJob).to receive(:perform_later).with(klaviyo_integration.id, newsletter_subscriber.email)
      invoke_subscriber
    end
  end
end
