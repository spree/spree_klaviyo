require 'spec_helper'

describe SpreeKlaviyo::SubscribeJob do
  subject { described_class.new.perform(klaviyo_integration.id, email, user&.id) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }

  context 'with user' do
    let(:user) { create(:user) }
    let(:email) { user.email }

    it 'calls SpreeKlaviyo::Subscribe' do
      expect(SpreeKlaviyo::Subscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: user.email, user: user).and_return(true)

      subject
    end
  end

  context 'without user' do
    let(:user) { nil }
    let(:email) { 'test@example.com' }

    it 'calls SpreeKlaviyo::Subscribe' do
      expect(SpreeKlaviyo::Subscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: email, user: nil).and_return(true)

      subject
    end
  end
end
