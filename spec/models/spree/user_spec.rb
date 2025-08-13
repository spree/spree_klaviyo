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
      context 'when using accepts_email_marketing column (integration style)' do
        before do
          skip 'accepts_email_marketing not present in this Spree version' unless Spree.user_class.new.respond_to?(:accepts_email_marketing)
        end

        it 'returns true when toggled from false to true on the same instance' do
          u = create(:user, accepts_email_marketing: false)
          expect(u.accepts_email_marketing).to be(false)
          # Ensure not already subscribed
          expect(u.send(:klaviyo_subscribed?)).to be(false)

          u.update!(accepts_email_marketing: true)
          expect(u.accepts_email_marketing).to be(true)
          expect(u.send(:marketing_opt_in_changed?)).to be(true)
        end

        it 'returns false when toggled to false' do
          u = create(:user, accepts_email_marketing: true)
          u.update!(accepts_email_marketing: false)
          expect(u.accepts_email_marketing).to be(false)
          expect(u.send(:marketing_opt_in_changed?)).to be(false)
        end

        it 'returns false when already Klaviyo-subscribed even if flag changed to true' do
          u = create(:user, accepts_email_marketing: false)
          u.klaviyo_subscribed = true
          u.update!(accepts_email_marketing: true)
          expect(u.accepts_email_marketing).to be(true)
          expect(u.send(:marketing_opt_in_changed?)).to be(false)
        end
      end
    end
  end
end
