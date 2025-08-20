require 'spec_helper'

describe SpreeKlaviyo::AnalyticsEventJob do
  include ActiveJob::TestHelper

  subject { described_class.new }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:event_name) { 'product_viewed' }
  let(:customer_properties) { { email: 'test@example.com', guest_id: 'visitor_123' } }
  let(:event_properties) { { resource: create(:product) } }
  let(:time) { Time.current }

  before do
    allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(true)
    allow(SpreeKlaviyo::Config).to receive(:[]).with(:job_queue).and_return('default')
    allow(::Spree::Integrations::Klaviyo).to receive(:active).and_return(double(first: klaviyo_integration))
  end

  describe '#perform' do
    context 'when configuration is enabled' do
      it 'processes the event successfully' do
        success_result = Spree::ServiceModule::Result.new(true, 'success')
        expect(klaviyo_integration).to receive(:create_event).with(
          event: event_name,
          resource: event_properties[:resource],
          email: customer_properties[:email],
          guest_id: customer_properties[:guest_id]
        ).and_return(success_result)

        subject.perform(event_name, customer_properties, event_properties, time)
      end

      it 'handles event creation failure gracefully' do
        error_result = Spree::ServiceModule::Result.new(false, 'API Error')
        expect(klaviyo_integration).to receive(:create_event).and_return(error_result)
        expect(Rails.logger).to receive(:error).with(
          "SpreeKlaviyo: Failed to track event #{event_name}: API Error"
        )

        subject.perform(event_name, customer_properties, event_properties, time)
      end

      it 'logs errors when exceptions occur' do
        expect(klaviyo_integration).to receive(:create_event).and_raise(StandardError.new('Network Error'))
        expect(Rails.logger).to receive(:error).with(
          "SpreeKlaviyo: Failed to track event #{event_name}: Network Error"
        )

        subject.perform(event_name, customer_properties, event_properties, time)
      end

      it 'does not re-raise exceptions' do
        expect(klaviyo_integration).to receive(:create_event).and_raise(StandardError.new('Network Error'))
        
        expect { subject.perform(event_name, customer_properties, event_properties, time) }.not_to raise_error
      end
    end

    context 'when configuration is disabled' do
      before do
        allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(false)
      end

      it 'returns early without processing' do
        expect(klaviyo_integration).not_to receive(:create_event)

        subject.perform(event_name, customer_properties, event_properties, time)
      end
    end

    context 'when no active integration is found' do
      before do
        allow(::Spree::Integrations::Klaviyo).to receive(:active).and_return(double(first: nil))
      end

      it 'returns early without processing' do
        expect(klaviyo_integration).not_to receive(:create_event)

        subject.perform(event_name, customer_properties, event_properties, time)
      end
    end
  end

  describe 'job configuration' do
    it 'uses the configured job queue' do
      expect(described_class.queue_name).to eq('default')
    end

    it 'inherits from BaseJob' do
      expect(described_class.superclass).to eq(SpreeKlaviyo::BaseJob)
    end
  end

  describe 'job enqueueing' do
    it 'can be enqueued with perform_later' do
      expect {
        described_class.perform_later(event_name, customer_properties, event_properties, time)
      }.to have_enqueued_job(described_class).with(event_name, customer_properties, event_properties, time)
    end

    it 'can be executed immediately with perform_now' do
      success_result = Spree::ServiceModule::Result.new(true, 'success')
      expect(klaviyo_integration).to receive(:create_event).and_return(success_result)

      described_class.perform_now(event_name, customer_properties, event_properties, time)
    end
  end
end
