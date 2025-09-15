require 'spec_helper'

RSpec.describe Spree.user_class, type: :model do
  include ActiveJob::TestHelper
  subject(:resource) { build(:newsletter_subscriber, user: user) }

  let(:user) { build(:user) }

  describe 'Klaviyo' do
    let!(:klaviyo_integration) { create(:klaviyo_integration) }

    describe '#subscribe_to_klaviyo' do
      before do
        ActiveJob::Base.queue_adapter = :test
        clear_enqueued_jobs
      end

      after { clear_enqueued_jobs }

      it 'enqueues a SubscribeJob' do
        expect {
          resource.send(:subscribe_to_klaviyo)
        }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(klaviyo_integration.id, resource.email)
      end

      context 'when no klaviyo integration exists' do
        before do
          klaviyo_integration.destroy!
        end

        it 'does not enqueue a SubscribeJob' do
          expect {
            resource.send(:subscribe_to_klaviyo)
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
        context 'when toggled to true' do
          let(:user) { create(:user, accepts_email_marketing: false) }

          it 'returns true' do
            expect(resource.accepts_email_marketing).to be(false)
            # Ensure not already subscribed
            expect(resource.send(:klaviyo_subscribed?)).to be(false)

            user.update!(accepts_email_marketing: true)
            expect(resource.accepts_email_marketing).to be(true)
            expect(resource.send(:marketing_opt_in_changed?)).to be(true)
          end
        end

        context 'when toggled to false' do
          let(:user) { create(:user, accepts_email_marketing: true) }

          it 'returns false' do
            user.update!(accepts_email_marketing: false)
            expect(resource.accepts_email_marketing).to be(false)
            expect(resource.send(:marketing_opt_in_changed?)).to be(false)
          end
        end

        context 'when already Klaviyo-subscribed even if flag changed to true' do
          let(:user) { create(:user, accepts_email_marketing: false) }

          it 'returns false ' do
            resource.klaviyo_subscribed = true
            user.update!(accepts_email_marketing: true)
            expect(resource.accepts_email_marketing).to be(true)
            expect(resource.send(:marketing_opt_in_changed?)).to be(false)
          end
        end
      end
    end
  end
end