require 'spec_helper'

describe SpreeKlaviyo::SubscribeJob do
  subject { described_class.new.perform(klaviyo_integration.id, subscriber.id) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:subscriber) { create(:newsletter_subscriber, user: user) }

  let(:user) { create(:user) }
  let(:email) { user.email }

  context 'with valid params' do
    it 'calls SpreeKlaviyo::Subscribe' do
      expect(SpreeKlaviyo::Subscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, subscriber: subscriber).and_return(true)

      subject
    end
  end
end