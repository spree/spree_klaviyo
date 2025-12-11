require 'spec_helper'

describe SpreeKlaviyo::AnalyticsEventJob do
  subject(:perform_job) { described_class.new.perform(klaviyo_integration.id, event_name, record, email, guest_id) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:event_name) { 'test_event' }
  let(:record) { { 'class' => 'Spree::Order', 'id' => order.id } }
  let!(:order) { create(:order) }
  let(:email) { 'test@example.com' }
  let(:guest_id) { 'guest_123' }
  let(:service_result) { instance_double(Spree::ServiceModule::Result, success?: true) }

  before do
    allow(SpreeKlaviyo::CreateEvent).to receive(:call).and_return(service_result)
  end

  context 'with valid parameters' do
    it 'calls SpreeKlaviyo::CreateEvent with correct arguments' do
      perform_job

      expect(SpreeKlaviyo::CreateEvent).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        event: event_name,
        resource: order,
        email: email,
        guest_id: guest_id
      )
    end
  end

  context 'without guest_id' do
    let(:guest_id) { nil }

    it 'calls SpreeKlaviyo::CreateEvent with nil guest_id' do
      perform_job

      expect(SpreeKlaviyo::CreateEvent).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        event: event_name,
        resource: order,
        email: email,
        guest_id: nil
      )
    end
  end

  context 'with string record (e.g. search query)' do
    let(:record) { 'red shoes' }

    it 'calls SpreeKlaviyo::CreateEvent with string as resource' do
      perform_job

      expect(SpreeKlaviyo::CreateEvent).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        event: event_name,
        resource: 'red shoes',
        email: email,
        guest_id: guest_id
      )
    end
  end

  context 'with nil record' do
    let(:record) { nil }

    it 'calls SpreeKlaviyo::CreateEvent with nil as resource' do
      perform_job

      expect(SpreeKlaviyo::CreateEvent).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        event: event_name,
        resource: nil,
        email: email,
        guest_id: guest_id
      )
    end
  end

  context 'when klaviyo_integration is not found' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect {
        described_class.new.perform(999_999, event_name, record, email, guest_id)
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

      expect(SpreeKlaviyo::CreateEvent).to have_received(:call).with(
        klaviyo_integration: klaviyo_integration,
        event: event_name,
        resource: order,
        email: email,
        guest_id: guest_id
      )
    end
  end
end
