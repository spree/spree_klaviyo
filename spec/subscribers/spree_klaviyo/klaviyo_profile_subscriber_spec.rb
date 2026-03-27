require 'spec_helper'

RSpec.describe SpreeKlaviyo::KlaviyoProfileSubscriber do
  let(:store) { Spree::Store.default }
  let!(:user) { create(:user, klaviyo_id: klaviyo_id) }
  let(:klaviyo_id) { nil }
  let!(:klaviyo_integration) { create(:klaviyo_integration, store: store) }

  describe '#handle_user_created' do
    let(:event) { Spree::Event.new(name: 'user.created', payload: { id: user.prefixed_id }, store_id: store.id) }

    context 'without visitor_id' do
      it 'enqueues CreateOrUpdateProfileJob' do
        expect(SpreeKlaviyo::CreateOrUpdateProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id)
        described_class.new.call(event)
      end

      it 'does not enqueue MergeVisitorProfileJob' do
        expect(SpreeKlaviyo::MergeVisitorProfileJob).not_to receive(:perform_later)
        described_class.new.call(event)
      end
    end

    context 'with visitor_id on event payload' do
      let(:event) do
        Spree::Event.new(
          name: 'user.created',
          payload: { id: user.prefixed_id, 'visitor_id' => 'payload-visitor' },
          store_id: store.id
        )
      end

      it 'enqueues MergeVisitorProfileJob with payload visitor_id' do
        expect(SpreeKlaviyo::MergeVisitorProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id, 'payload-visitor')
        described_class.new.call(event)
      end
    end

    context 'with visitor_id on both payload and user' do
      let(:klaviyo_visitor_id) { 'stored-visitor' }
      let(:event) do
        Spree::Event.new(
          name: 'user.created',
          payload: { id: user.prefixed_id, 'visitor_id' => 'payload-visitor' },
          store_id: store.id
        )
      end

      it 'prefers payload visitor_id' do
        expect(SpreeKlaviyo::MergeVisitorProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id, 'payload-visitor')
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
    context 'with user.updated event' do
      let(:event) { Spree::Event.new(name: 'user.updated', payload: { id: user.prefixed_id }, store_id: store.id) }

      it 'enqueues CreateOrUpdateProfileJob' do
        expect(SpreeKlaviyo::CreateOrUpdateProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id)
        described_class.new.call(event)
      end

      context 'without klaviyo integration' do
        before { klaviyo_integration.destroy! }

        it 'does not enqueue CreateOrUpdateProfileJob' do
          expect(SpreeKlaviyo::CreateOrUpdateProfileJob).not_to receive(:perform_later)
          described_class.new.call(event)
        end
      end
    end

    context 'with address.created event' do
      let(:address) { create(:address, user: user) }
      let(:event) do
        Spree::Event.new(
          name: 'address.created',
          payload: { 'id' => address.id, 'user_id' => user.id },
          store_id: store.id
        )
      end

      it 'resolves the user from user_id and enqueues CreateOrUpdateProfileJob' do
        expect(SpreeKlaviyo::CreateOrUpdateProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id)
        described_class.new.call(event)
      end
    end

    context 'with address.updated' do
      let(:address) { create(:address, user: user) }
      let(:event) do
        Spree::Event.new(
          name: 'address.updated',
          payload: { 'id' => address.id, 'user_id' => user.id },
          store_id: store.id
        )
      end

      it 'resolves the user from user_id and enqueues CreateOrUpdateProfileJob' do
        expect(SpreeKlaviyo::CreateOrUpdateProfileJob).to receive(:perform_later)
          .with(klaviyo_integration.id, user.id)
        described_class.new.call(event)
      end
    end
  end
end
