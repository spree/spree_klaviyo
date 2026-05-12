require 'spec_helper'

RSpec.describe 'Klaviyo end-to-end newsletter subscription' do
  let(:store) { Spree::Store.default }
  let!(:klaviyo_integration) { create(:klaviyo_integration, store: store) }
  let(:email) { 'user@example.com' }
  let(:subscriber) { Spree::NewsletterSubscriber.find_by(email: email) }

  context 'when Klaviyo API succeeds' do
    it 'creates and marks subscriber as subscribed in Klaviyo' do
      VCR.use_cassette('services/spree_klaviyo/subscribe/success') do
        perform_enqueued_jobs(only: [Spree::Events::SubscriberJob, SpreeKlaviyo::SubscribeJob]) do
          Spree::Newsletter::Subscribe.new(email: email).call
        end
      end

      expect(subscriber).to be_present
      expect(
        ActiveModel::Type::Boolean.new.cast(subscriber.get_metafield('klaviyo.subscribed')&.value)
      ).to eq(true)
    end
  end

  context 'when Klaviyo API fails' do
    let!(:klaviyo_integration) { create(:klaviyo_integration, store: store, preferred_default_newsletter_list_id: 'invalid-list-id') }

    it 'creates newsletter subscriber but does not mark as subscribed' do
      VCR.use_cassette('services/spree_klaviyo/subscribe/failure') do
        perform_enqueued_jobs(only: [Spree::Events::SubscriberJob, SpreeKlaviyo::SubscribeJob]) do
          Spree::Newsletter::Subscribe.new(email: email).call
        end
      end

      expect(subscriber).to be_present
      expect(subscriber.get_metafield('klaviyo.subscribed')).to be_nil
    end
  end
end
