require 'spec_helper'

describe SpreeKlaviyo::Subscribe do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, subscriber: subscriber) }

  let(:subscriber) { create(:newsletter_subscriber, user: user, email: email, klaviyo_subscribed: klaviyo_subscribed) }
  let(:user) { create(:user) }
  let(:klaviyo_subscribed) { false }
  let(:email) { 'foo@bar.com' }

  let(:success) { true }
  before do
    allow(klaviyo_integration).to receive(:subscribe_user).with(subscriber.email).and_return(Spree::ServiceModule::Result.new(success, subscriber))
  end

  context 'when klaviyo integration is exists' do
    let!(:klaviyo_integration) { create(:klaviyo_integration) }

    context 'when subscriber was not subscribed yet' do
      let(:klaviyo_subscribed) { false }

      it 'marks subscriber as subscribed' do
        expect { subject }.to change { subscriber.reload.klaviyo_subscribed? }.from(false).to(true)
      end

      it 'calls subscribe_user' do
        expect(klaviyo_integration).to receive(:subscribe_user).once

        subject
      end
    end

    context 'when subscribe request fails' do
      let(:success) { false }

      it 'does not mark subscriber as subscribed' do
        expect { subject }.not_to change { subscriber.reload.klaviyo_subscribed? }
      end
    end
  end

  context 'when klaviyo integration is not found' do
    let(:klaviyo_integration) { nil }

    it 'returns a failure' do
      expect(subject.success?).to be false
      expect(subject.error.value).to eq Spree.t('admin.integrations.klaviyo.not_found')
    end
  end
end