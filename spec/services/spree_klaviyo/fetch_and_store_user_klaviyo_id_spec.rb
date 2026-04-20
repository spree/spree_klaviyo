require 'spec_helper'

describe SpreeKlaviyo::FetchAndStoreUserKlaviyoId do
  describe '#call' do
    subject(:call) { described_class.call(klaviyo_integration: klaviyo_integration, user: user) }

    let(:klaviyo_integration) { create(:klaviyo_integration) }
    let(:user) { create(:user, accepts_email_marketing: true, klaviyo_id: klaviyo_id) }
    let(:klaviyo_id) { '123' }

    context 'when user has klaviyo_id' do
      it { is_expected.to be_success }

      it 'returns the klaviyo_id' do
        expect(call.value).to eq(klaviyo_id)
      end
    end

    context 'when user does not have klaviyo_id' do
      let(:klaviyo_id) { nil }

      before do
        allow(klaviyo_integration).to receive(:fetch_profile).with({ email: user.email }).and_return(fetch_profile_result)
      end

      context 'when user has profile in Klaviyo' do
        let(:fetch_profile_result) { Spree::ServiceModule::Result.new(true, { data: [{ id: '123' }] }.to_json) }

        it { is_expected.to be_success }

        it 'returns the klaviyo_id' do
          expect(call.value).to eq('123')
        end
      end

      context 'when user does not have profile in klaviyo' do
        let(:fetch_profile_result) { Spree::ServiceModule::Result.new(false, user.email) }

        it { is_expected.to be_failure }
      end
    end
  end
end
