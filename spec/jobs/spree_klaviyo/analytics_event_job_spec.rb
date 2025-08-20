require 'spec_helper'

describe SpreeKlaviyo::AnalyticsEventJob do
  include ActiveJob::TestHelper

  let(:event_name) { 'test_event' }
  let(:customer_properties) { { email: 'test@example.com', guest_id: 'visitor_123' } }
  let(:event_properties) { { resource: 'test_resource' } }
  let(:time) { Time.current }
  let(:klaviyo_integration) { double('KlaviyoIntegration') }
  let(:store) { double('Store') }

  before do
    allow(subject).to receive(:store).and_return(store)
    allow(store).to receive(:integrations).and_return(double('Integrations'))
    allow(store.integrations).to receive(:active).and_return(double('ActiveIntegrations'))
    allow(store.integrations.active).to receive(:find_by).with(type: 'Spree::Integrations::Klaviyo').and_return(klaviyo_integration)
  end

  describe '#perform' do
    it 'processes the event successfully' do
      success_result = Spree::ServiceModule::Result.new(true, 'success')
      expect(klaviyo_integration).to receive(:create_event).and_return(success_result)
      subject.perform(event_name, customer_properties, event_properties, time)
    end

    it 'handles event creation failure gracefully' do
      error_result = Spree::ServiceModule::Result.new(false, 'API Error')
      expect(klaviyo_integration).to receive(:create_event).and_return(error_result)
      expect(Rails.logger).to receive(:error).with("SpreeKlaviyo: Failed to track event #{event_name}: API Error")
      subject.perform(event_name, customer_properties, event_properties, time)
    end

    it 'handles exceptions gracefully' do
      expect(klaviyo_integration).to receive(:create_event).and_raise(StandardError.new('Network Error'))
      expect(Rails.logger).to receive(:error).with("SpreeKlaviyo: Failed to track event #{event_name}: Network Error")
      subject.perform(event_name, customer_properties, event_properties, time)
    end

    it 'does not re-raise exceptions' do
      expect(klaviyo_integration).to receive(:create_event).and_raise(StandardError.new('Network Error'))
      expect { subject.perform(event_name, customer_properties, event_properties, time) }.not_to raise_error
    end
  end

  describe 'job configuration' do
    it 'uses the correct queue' do
      expect(SpreeKlaviyo.queue).to eq(Spree.queues.default)
      expect(subject.queue_name).to eq(Spree.queues.default.to_s)
    end

    it 'inherits from BaseJob' do
      expect(subject).to be_a(SpreeKlaviyo::BaseJob)
    end
  end

  describe 'job enqueueing' do
    it 'can be enqueued' do
      expect {
        SpreeKlaviyo::AnalyticsEventJob.perform_later(event_name, customer_properties, event_properties, time)
      }.to have_enqueued_job(SpreeKlaviyo::AnalyticsEventJob)
    end

    it 'enqueues with correct parameters' do
      expect {
        SpreeKlaviyo::AnalyticsEventJob.perform_later(event_name, customer_properties, event_properties, time)
      }.to have_enqueued_job.with(event_name, customer_properties, event_properties, time)
    end
  end
end
