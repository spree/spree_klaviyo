require 'spec_helper'

describe SpreeKlaviyo::SubscribeJob do
  subject { described_class.new.perform(klaviyo_integration.id, email, resource&.id, 'Spree::NewsletterSubscriber') }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:resource) { create(:newsletter_subscriber, user: user) }

  context 'with resource' do
    let(:user) { create(:user) }
    let(:email) { user.email }

    it 'calls SpreeKlaviyo::Subscribe' do
      expect(SpreeKlaviyo::Subscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: user.email, resource: resource).and_return(true)

      subject
    end
  end

  context 'without resource' do
    let(:resource) { nil }
    let(:email) { 'test@example.com' }

    it 'calls SpreeKlaviyo::Subscribe' do
      expect(SpreeKlaviyo::Subscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: email, resource: nil).and_return(true)

      subject
    end
  end
end
