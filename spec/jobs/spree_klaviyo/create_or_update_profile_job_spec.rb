require 'spec_helper'

describe SpreeKlaviyo::CreateOrUpdateProfileJob do
  subject(:perform_job) { described_class.new.perform(klaviyo_integration.id, user.id, guest_id) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:user) { create(:user) }
  let(:guest_id) { 'guest_123' }
  let(:service_result) { instance_double(Spree::ServiceModule::Result, success?: true) }

  before do
    allow(SpreeKlaviyo::CreateOrUpdateProfile).to receive(:call).and_return(service_result)
  end

  context 'with valid parameters' do
    it 'calls SpreeKlaviyo::CreateOrUpdateProfile with correct arguments' do
      perform_job

      expect(SpreeKlaviyo::CreateOrUpdateProfile).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        user: user,
        guest_id: guest_id
      )
    end
  end

  context 'without guest_id' do
    let(:guest_id) { nil }

    it 'calls SpreeKlaviyo::CreateOrUpdateProfile with nil guest_id' do
      perform_job

      expect(SpreeKlaviyo::CreateOrUpdateProfile).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        user: user,
        guest_id: nil
      )
    end
  end

  context 'when user is not found' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect {
        described_class.new.perform(klaviyo_integration.id, 999_999, guest_id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when klaviyo_integration is not found' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect {
        described_class.new.perform(999_999, user.id, guest_id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when service call fails' do
    let(:service_result) { instance_double(Spree::ServiceModule::Result, success?: false, error: 'Some error') }

    it 'does not raise an error' do
      expect { perform_job }.not_to raise_error
    end

    it 'calls the service with correct arguments' do
      perform_job

      expect(SpreeKlaviyo::CreateOrUpdateProfile).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        user: user,
        guest_id: guest_id
      )
    end
  end
end
