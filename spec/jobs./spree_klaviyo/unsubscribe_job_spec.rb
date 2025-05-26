require 'spec_helper'

describe SpreeKlaviyo::UnsubscribeJob do
  subject { described_class.new.perform(klaviyo_integration.id, email, user&.id) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:user) { create(:user) }
  let(:email) { user.email }

  it 'calls SpreeKlaviyo::Unsubscribe with user' do
    expect(SpreeKlaviyo::Unsubscribe).to receive(:call).with(klaviyo_integration: klaviyo_integration, email: user.email, user: user).and_return(true)

    subject
  end
end
