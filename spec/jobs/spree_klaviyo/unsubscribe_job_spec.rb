require 'spec_helper'

describe SpreeKlaviyo::UnsubscribeJob do
  subject { described_class.new.perform(klaviyo_integration.id, email) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:email) { 'test@example.com' }

  context 'with valid params' do
    it 'calls SpreeKlaviyo::Unsubscribe' do
      expect(SpreeKlaviyo::Unsubscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: email).and_return(true)

      subject
    end
  end
end
