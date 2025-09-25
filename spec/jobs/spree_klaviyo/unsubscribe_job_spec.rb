require 'spec_helper'

describe SpreeKlaviyo::UnsubscribeJob do
  subject { described_class.new.perform(klaviyo_integration.id, email, resource_id, resource_type) }

  let(:resource_id) { nil }
  let(:resource_type) { nil }
  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:email) { 'test@example.com' }

  context 'without resource' do
    it 'calls SpreeKlaviyo::Unsubscribe with nil resource' do
      expect(SpreeKlaviyo::Unsubscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: email, resource: nil).and_return(true)

      subject
    end
  end

  context 'with resource' do
    let(:resource_id) { user.id }
    let(:resource_type) { Spree.user_class.name }
    let(:user) { create(:user, email: email) }

    it 'calls SpreeKlaviyo::Unsubscribe with user' do
      expect(SpreeKlaviyo::Unsubscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: user.email, resource: user).and_return(true)

      subject
    end
  end
end
