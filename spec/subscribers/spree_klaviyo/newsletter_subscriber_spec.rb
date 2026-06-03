require 'spec_helper'

RSpec.describe SpreeKlaviyo::NewsletterSubscriber do
  let(:store) { Spree::Store.default }
  let!(:klaviyo_integration) { create(:klaviyo_integration, store: store) }

  around do |example|
    perform_enqueued_jobs(only: Spree::Events::SubscriberJob) { example.run }
  end

  describe '#newsletter_subscriber.created event' do
    let(:email) { 'customer@example.com' }

    it 'enqueues SubscribeJob with correct arguments' do
      expect {
        Spree::Newsletter::Subscribe.new(email: email).call
      }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with { |integration_id, subscriber_id|
        expect(integration_id).to eq(klaviyo_integration.id)
        expect(Spree::NewsletterSubscriber.find(subscriber_id).email).to eq(email)
      }
    end

    it 'does not enqueue SubscribeJob when subscriber already exists' do
      create(:newsletter_subscriber, email: email)

      expect {
        Spree::Newsletter::Subscribe.new(email: email).call
      }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue SubscribeJob' do
        expect {
          Spree::Newsletter::Subscribe.new(email: email).call
        }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
      end
    end

    context 'with the same email already subscribed on another store' do
      let!(:store_b) { create(:store) }
      let!(:integration_b) { create(:klaviyo_integration, store: store_b) }
      let(:shared_email) { 'shared@example.com' }

      it 'enqueues SubscribeJob for the event\'s subscriber, not the same-email row from another store' do
        create(:newsletter_subscriber, email: shared_email, store: store)

        expect {
          create(:newsletter_subscriber, email: shared_email, store: store_b)
        }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with { |integration_id, subscriber_id|
          expect(integration_id).to eq(integration_b.id)
          expect(Spree::NewsletterSubscriber.find(subscriber_id).store_id).to eq(store_b.id)
        }
      end
    end

    context 'when the subscriber\'s store has no Klaviyo integration' do
      let!(:other_store) { create(:store) }

      it 'does not enqueue SubscribeJob' do
        expect {
          create(:newsletter_subscriber, email: 'only-on-other@example.com', store: other_store)
        }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
      end
    end
  end

  describe '#newsletter_subscriber.deleted event' do
    let!(:existing_subscriber) { create(:newsletter_subscriber) }

    it 'enqueues UnsubscribeJob with correct arguments' do
      expect {
        existing_subscriber.destroy!
      }.to have_enqueued_job(SpreeKlaviyo::UnsubscribeJob).with(klaviyo_integration.id, existing_subscriber.email)
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue UnsubscribeJob' do
        expect {
          existing_subscriber.destroy!
        }.not_to have_enqueued_job(SpreeKlaviyo::UnsubscribeJob)
      end
    end

    context 'when event.store_id is nil' do
      let(:event) do
        Spree::Event.new(
          name: 'newsletter_subscriber.deleted',
          payload: { 'email' => existing_subscriber.email },
          store_id: nil
        )
      end

      it 'does not enqueue UnsubscribeJob' do
        expect {
          described_class.new.call(event)
        }.not_to have_enqueued_job(SpreeKlaviyo::UnsubscribeJob)
      end
    end

    context 'when unsubscribing on another store' do
      let!(:store_b) { create(:store) }
      let!(:integration_b) { create(:klaviyo_integration, store: store_b) }
      let(:shared_email) { 'shared@example.com' }

      let(:event) do
        Spree::Event.new(
          name: 'newsletter_subscriber.deleted',
          payload: { 'email' => shared_email },
          store_id: store_b.id
        )
      end

      it 'uses event.store_id to locate the integration (not Spree::Store.default)' do
        expect {
          described_class.new.call(event)
        }.to have_enqueued_job(SpreeKlaviyo::UnsubscribeJob).with(integration_b.id, shared_email)
      end
    end
  end
end
