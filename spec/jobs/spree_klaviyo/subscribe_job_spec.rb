require 'spec_helper'

describe SpreeKlaviyo::SubscribeJob do
  subject { described_class.new.perform(klaviyo_integration.id, email, user_id, custom_properties) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:user) { create(:user) }
  let(:email) { user.email }
  let(:user_id) { user.id }
  let(:custom_properties) { {} }

  describe '#perform' do
    it 'calls the Subscribe service with correct parameters' do
      expect(SpreeKlaviyo::Subscribe).to receive(:call).with(
        klaviyo_integration: klaviyo_integration,
        email: email,
        user: user,
        custom_properties: custom_properties
      )

      subject
    end

    context 'with custom properties including ZIP code' do
      let(:custom_properties) { { zipcode: '12345', source: 'newsletter_form' } }

      it 'passes custom properties to the Subscribe service' do
        expect(SpreeKlaviyo::Subscribe).to receive(:call).with(
          klaviyo_integration: klaviyo_integration,
          email: email,
          user: user,
          custom_properties: custom_properties
        )

        subject
      end
    end

    context 'when user_id is nil' do
      let(:user_id) { nil }

      it 'calls the Subscribe service with nil user' do
        expect(SpreeKlaviyo::Subscribe).to receive(:call).with(
          klaviyo_integration: klaviyo_integration,
          email: email,
          user: nil,
          custom_properties: custom_properties
        )

        subject
      end
    end
  end
end
