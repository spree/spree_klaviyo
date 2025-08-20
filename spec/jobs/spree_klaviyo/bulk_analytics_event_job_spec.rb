require 'spec_helper'

describe SpreeKlaviyo::BulkAnalyticsEventJob do
  include ActiveJob::TestHelper

  subject { described_class.new }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:events) do
    [
      {
        event_name: 'product_viewed',
        customer_properties: { email: 'test1@example.com', guest_id: 'visitor_1' },
        event_properties: { resource: create(:product) },
        time: Time.current
      },
      {
        event_name: 'product_added',
        customer_properties: { email: 'test2@example.com', guest_id: 'visitor_2' },
        event_properties: { resource: create(:order) },
        time: Time.current
      }
    ]
  end

  before do
    allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(true)
    allow(SpreeKlaviyo::Config).to receive(:[]).with(:job_queue).and_return('default')
    allow(::Spree::Integrations::Klaviyo).to receive(:active).and_return(double(first: klaviyo_integration))
  end

  describe '#perform' do
    context 'when configuration is enabled' do
      it 'processes all events successfully' do
        events.each do |event_data|
          success_result = Spree::ServiceModule::Result.new(true, 'success')
          expect(klaviyo_integration).to receive(:create_event).with(
            event: event_data[:event_name],
            resource: event_data[:event_properties][:resource],
            email: event_data[:customer_properties][:email],
            guest_id: event_data[:customer_properties][:guest_id]
          ).and_return(success_result)
        end

        subject.perform(events)
      end

      it 'handles individual event failures gracefully' do
        # First event succeeds
        success_result = Spree::ServiceModule::Result.new(true, 'success')
        expect(klaviyo_integration).to receive(:create_event).with(
          event: events[0][:event_name],
          resource: events[0][:event_properties][:resource],
          email: events[0][:customer_properties][:email],
          guest_id: events[0][:customer_properties][:guest_id]
        ).and_return(success_result)

        # Second event fails
        error_result = Spree::ServiceModule::Result.new(false, 'API Error')
        expect(klaviyo_integration).to receive(:create_event).with(
          event: events[1][:event_name],
          resource: events[1][:event_properties][:resource],
          email: events[1][:customer_properties][:email],
          guest_id: events[1][:customer_properties][:guest_id]
        ).and_return(error_result)

        expect(Rails.logger).to receive(:error).with(
          "SpreeKlaviyo: Failed to track event #{events[1][:event_name]}: API Error"
        )

        subject.perform(events)
      end

      it 'continues processing other events when one fails' do
        # First event fails with exception
        expect(klaviyo_integration).to receive(:create_event).with(
          event: events[0][:event_name],
          resource: events[0][:event_properties][:resource],
          email: events[0][:customer_properties][:email],
          guest_id: events[0][:customer_properties][:guest_id]
        ).and_raise(StandardError.new('Network Error'))

        # Second event should still be processed
        success_result = Spree::ServiceModule::Result.new(true, 'success')
        expect(klaviyo_integration).to receive(:create_event).with(
          event: events[1][:event_name],
          resource: events[1][:event_properties][:resource],
          email: events[1][:customer_properties][:email],
          guest_id: events[1][:customer_properties][:guest_id]
        ).and_return(success_result)

        expect(Rails.logger).to receive(:error).with(
          "SpreeKlaviyo: Failed to track event #{events[0][:event_name]}: Network Error"
        )

        subject.perform(events)
      end

      it 'logs errors when exceptions occur during bulk processing' do
        expect(klaviyo_integration).to receive(:create_event).and_raise(StandardError.new('Bulk Processing Error'))
        expect(Rails.logger).to receive(:error).with(
          "SpreeKlaviyo: Failed to track event bulk_events: Bulk Processing Error"
        )

        subject.perform(events)
      end

      it 'does not re-raise exceptions' do
        expect(klaviyo_integration).to receive(:create_event).and_raise(StandardError.new('Bulk Processing Error'))
        
        expect { subject.perform(events) }.not_to raise_error
      end
    end

    context 'when configuration is disabled' do
      before do
        allow(SpreeKlaviyo::Config).to receive(:[]).with(:enabled).and_return(false)
      end

      it 'returns early without processing' do
        expect(klaviyo_integration).not_to receive(:create_event)

        subject.perform(events)
      end
    end

    context 'when events array is blank' do
      it 'returns early without processing' do
        expect(klaviyo_integration).not_to receive(:create_event)

        subject.perform([])
      end

      it 'returns early when events is nil' do
        expect(klaviyo_integration).not_to receive(:create_event)

        subject.perform(nil)
      end
    end

    context 'when no active integration is found' do
      before do
        allow(::Spree::Integrations::Klaviyo).to receive(:active).and_return(double(first: nil))
      end

      it 'returns early without processing' do
        expect(klaviyo_integration).not_to receive(:create_event)

        subject.perform(events)
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
        described_class.perform_later(events)
      }.to have_enqueued_job(described_class).with(events)
    end

    it 'can be executed immediately with perform_now' do
      events.each do |event_data|
        success_result = Spree::ServiceModule::Result.new(true, 'success')
        expect(klaviyo_integration).to receive(:create_event).and_return(success_result)
      end

      described_class.perform_now(events)
    end
  end
end
