require 'spec_helper'

describe SpreeKlaviyo::UnsubscribeJob do
  subject(:perform) { described_class.new.perform(klaviyo_integration.id, subscriber_id) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:subscriber) { create(:newsletter_subscriber) }
  let(:subscriber_id) { subscriber.id }

  context 'with subscriber' do
    it 'calls SpreeKlaviyo::Unsubscribe' do
      expect(SpreeKlaviyo::Unsubscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, subscriber: subscriber).and_return(true)

      subject
    end
  end

  context 'without subscriber' do
    let(:subscriber_id) { nil }

    it 'calls SpreeKlaviyo::Unsubscribe' do
      expect(SpreeKlaviyo::Unsubscribe).to_not receive(:call)

      subject
    end
  end
end
