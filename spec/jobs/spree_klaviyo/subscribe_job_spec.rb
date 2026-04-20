require 'spec_helper'

describe SpreeKlaviyo::SubscribeJob do
  subject(:perform) { described_class.new.perform(klaviyo_integration.id, subscriber_id) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:subscriber) { create(:newsletter_subscriber) }
  let(:subscriber_id) { subscriber.id }

  context 'with subscriber' do
    it 'calls SpreeKlaviyo::Subscribe' do
      expect(SpreeKlaviyo::Subscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, subscriber: subscriber).and_return(true)

      perform
    end
  end

  context 'without subscriber' do
    let(:subscriber_id) { nil }

    it 'calls SpreeKlaviyo::Subscribe' do
      expect(SpreeKlaviyo::Subscribe).to_not receive(:call)

      perform
    end
  end
end
