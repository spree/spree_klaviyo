require 'spec_helper'

describe SpreeKlaviyo::CreateEventJob do
  subject(:perform_job) { described_class.new.perform(*params) }

  let(:params) do
    [
      klaviyo_integration_id,
      event,
      resource_id,
      resource_type,
      email,
      guest_id
    ]
  end

  let(:klaviyo_integration_id) { klaviyo_integration.id }
  let(:event) { 'Something happened' }
  let(:resource_type) { 'Spree::Order' }
  let(:resource_id) { order.id }
  let(:email) { 'guest@example.com' }
  let(:guest_id) { 'visitor-abc-123' }

  let(:order) { create(:order) }
  let(:klaviyo_integration) { create(:klaviyo_integration) }

  let(:service_result) { instance_double(Spree::ServiceModule::Result, success?: true) }

  before do
    allow(SpreeKlaviyo::CreateEvent).to receive(:call).and_return(service_result)
  end

  context 'with valid parameters' do
    it 'calls SpreeKlaviyo::CreateOrUpdateProfile with correct arguments' do
      perform_job

      expect(SpreeKlaviyo::CreateEvent).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        event: event,
        resource: order,
        email: email,
        guest_id: guest_id
      )
    end
  end

  context 'without invalid parameters' do
    context 'when resource is not found' do
      let(:resource_id) { 999_999 }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { perform_job }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when klaviyo_integration is not found' do
      let(:klaviyo_integration_id) { 999_999 }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { perform_job }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
