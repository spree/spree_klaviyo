require 'spec_helper'

describe SpreeKlaviyo::Subscribe do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, subscriber: subscriber) }

  let(:subscriber) { create(:newsletter_subscriber, email: 'user@example.com') }
  let(:klaviyo_integration) { create(:klaviyo_integration) }

  context 'when subscribe request succeeds' do
    it 'returns success' do
      VCR.use_cassette('services/spree_klaviyo/subscribe/success') do
        expect(subject).to be_success
      end
    end

    it 'marks subscriber as subscribed' do
      VCR.use_cassette('services/spree_klaviyo/subscribe/success') do
        expect { subject }.to change {
          ActiveModel::Type::Boolean.new.cast(subscriber.get_metafield('klaviyo.subscribed')&.value)
        }.from(nil).to(true)
      end
    end
  end

  context 'when subscribe request fails' do
    let(:klaviyo_integration) { create(:klaviyo_integration, preferred_default_newsletter_list_id: 'invalid-list-id') }

    it 'returns failure' do
      VCR.use_cassette('services/spree_klaviyo/subscribe/failure') do
        expect(subject).to be_failure
      end
    end
  end
end
