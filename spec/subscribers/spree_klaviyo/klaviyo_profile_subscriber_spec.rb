require 'spec_helper'

RSpec.describe SpreeKlaviyo::KlaviyoProfileSubscriber do
  let(:store) { Spree::Store.default }
  let!(:user) { create(:user) }
  let!(:klaviyo_integration) { create(:klaviyo_integration, store: store) }

  describe '#handle_user_created' do
    let(:event) { Spree::Event.new(name: 'user.created', payload: { id: user.prefixed_id }, store_id: store.id) }

    context 'without visitor_id' do
      it 'enqueues CreateOrUpdateProfileJob' do
        expect(SpreeKlaviyo::CreateOrUpdateProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id)
        described_class.new.call(event)
      end
    end

    context 'with visitor_id stored on user' do
      before { user.update_columns(private_metadata: (user.private_metadata || {}).merge('klaviyo_visitor_id' => 'visitor-123')) }

      it 'enqueues MergeVisitorProfileJob' do
        expect(SpreeKlaviyo::MergeVisitorProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id, 'visitor-123')
        described_class.new.call(event)
      end
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue any job' do
        expect(SpreeKlaviyo::CreateOrUpdateProfileJob).not_to receive(:perform_later)
        expect(SpreeKlaviyo::MergeVisitorProfileJob).not_to receive(:perform_later)
        described_class.new.call(event)
      end
    end
  end

  describe '#handle_profile_upsert' do
    let(:event) { Spree::Event.new(name: 'user.updated', payload: { id: user.prefixed_id }, store_id: store.id) }

    it 'enqueues CreateOrUpdateProfileJob' do
      expect(SpreeKlaviyo::CreateOrUpdateProfileJob).to receive(:perform_later)
        .with(klaviyo_integration.id, user.id)
      described_class.new.call(event)
    end

    context 'with visitor_id stored on user' do
      before { user.update_columns(private_metadata: (user.private_metadata || {}).merge('klaviyo_visitor_id' => 'visitor-123')) }

      it 'does not enqueue MergeVisitorProfileJob' do
        expect(SpreeKlaviyo::MergeVisitorProfileJob).not_to receive(:perform_later)
        expect(SpreeKlaviyo::CreateOrUpdateProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id)
        described_class.new.call(event)
      end
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue any job' do
        expect(SpreeKlaviyo::CreateOrUpdateProfileJob).not_to receive(:perform_later)
        described_class.new.call(event)
      end
    end
  end
end
