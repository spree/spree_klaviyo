require 'spec_helper'

describe SpreeKlaviyo::Unsubscribe do
  subject(:call) { described_class.call(klaviyo_integration: klaviyo_integration, subscriber: subscriber) }

  let(:subscriber) { create(:newsletter_subscriber, email: 'unsubscribe-user@example.com') }
  let(:klaviyo_integration) { create(:klaviyo_integration) }

  before do
    subscriber.set_metafield('klaviyo.subscribed', true)
  end

  context 'when unsubscribe request succeeds' do
    it 'returns success' do
      VCR.use_cassette('services/spree_klaviyo/unsubscribe/success') do
        expect(call).to be_success
      end
    end

    it 'marks subscriber as not subscribed' do
      VCR.use_cassette('services/spree_klaviyo/unsubscribe/success') do
        expect { call }.to change {
          subscriber.get_metafield('klaviyo.subscribed').serialize_value
        }.from(true).to(false)
      end
    end
  end

  context 'when unsubscribe request fails' do
    let(:klaviyo_integration) { create(:klaviyo_integration, preferred_default_newsletter_list_id: 'invalid-list-id') }

    it 'returns failure' do
      VCR.use_cassette('services/spree_klaviyo/unsubscribe/failure') do
        expect(call).to be_failure
      end
    end
  end
end
