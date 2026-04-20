require 'spec_helper'

describe SpreeKlaviyo::UnsubscribeJob do
  subject(:perform) { described_class.new.perform(klaviyo_integration.id, email) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:email) { 'unsubscribe-user@example.com' }

  context 'with subscriber' do
    it 'calls SpreeKlaviyo::Unsubscribe' do
      expect(SpreeKlaviyo::Unsubscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: email).and_return(true)

      subject
    end
  end
end
