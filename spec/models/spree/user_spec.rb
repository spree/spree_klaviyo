require 'spec_helper'

RSpec.describe Spree.user_class, type: :model do
  include ActiveJob::TestHelper

  describe 'Klaviyo' do
    let(:user) { build(:user) }
    let!(:klaviyo_integration) { create(:klaviyo_integration) }

    describe '#subscribe_to_klaviyo' do
      before do
        ActiveJob::Base.queue_adapter = :test
        clear_enqueued_jobs
      end

      after { clear_enqueued_jobs }

      it 'enqueues a SubscribeJob' do
        expect {
          user.send(:subscribe_to_klaviyo)
        }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(klaviyo_integration.id, user.email)
      end

      context 'when no klaviyo integration exists' do
        before do
          klaviyo_integration.destroy!
        end

        it 'does not enqueue a SubscribeJob' do
          expect {
            user.send(:subscribe_to_klaviyo)
          }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
        end
      end

      context 'when klaviyo integration is not active' do
        before do
          klaviyo_integration.update(active: false)
        end

        it 'does not enqueue a SubscribeJob' do
          expect {
            user.send(:subscribe_to_klaviyo)
          }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
        end
      end
    end

    describe '#marketing_opt_in_changed? (private)' do
      before do
        allow(user).to receive(:klaviyo_subscribed?).and_return(false)
      end

      it 'returns true when flag changed and accepted_marketing is true' do
        allow(user).to receive(:saved_change_to_accepted_marketing?).and_return(true)
        allow(user).to receive(:accepted_marketing?).and_return(true)
        expect(user.send(:marketing_opt_in_changed?)).to be(true)
      end

      it 'returns false when flag did not change' do
        allow(user).to receive(:saved_change_to_accepted_marketing?).and_return(false)
        allow(user).to receive(:accepted_marketing?).and_return(true)
        expect(user.send(:marketing_opt_in_changed?)).to be(false)
      end

      it 'returns false when accepted_marketing is false' do
        allow(user).to receive(:saved_change_to_accepted_marketing?).and_return(true)
        allow(user).to receive(:accepted_marketing?).and_return(false)
        expect(user.send(:marketing_opt_in_changed?)).to be(false)
      end

      it 'returns false when already subscribed (prevents duplicate enqueues)' do
        allow(user).to receive(:klaviyo_subscribed?).and_return(true)
        allow(user).to receive(:saved_change_to_accepted_marketing?).and_return(true)
        allow(user).to receive(:accepted_marketing?).and_return(true)
        expect(user.send(:marketing_opt_in_changed?)).to be(false)
      end
    end
  end
end
