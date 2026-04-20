require 'spec_helper'

describe SpreeKlaviyo::Unsubscribe do
  subject(:call) { described_class.call(klaviyo_integration: klaviyo_integration, email: email) }

  let(:email) { 'unsubscribe-user@example.com' }
  let(:klaviyo_integration) { create(:klaviyo_integration) }

  context 'when unsubscribe request succeeds' do
    it 'returns success' do
      VCR.use_cassette('services/spree_klaviyo/unsubscribe/success') do
        expect(call).to be_success
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
