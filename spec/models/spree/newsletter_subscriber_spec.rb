require 'spec_helper'

RSpec.describe Spree::NewsletterSubscriber, type: :model do
  include ActiveJob::TestHelper
  subject(:resource) { build(:newsletter_subscriber, user: user) }

  let(:user) { build(:user) }

  describe 'Klaviyo' do
    let!(:klaviyo_integration) { create(:klaviyo_integration) }

    describe '#subscribe' do
      subject(:subscribe) { Spree::NewsletterSubscriber.subscribe(**params) }
      let(:params) { { email: user.email, user: user } }

      context 'with user asssigned' do
        let(:user) { create(:user, accepts_email_marketing: false) }

        it 'enqueues a SubscribeJob a job and changes user accepts_email_marketing' do
          expect { subscribe }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(klaviyo_integration.id, kind_of(Integer)).once
                             .and change { user.reload.accepts_email_marketing }.from(false).to(true)
        end

        it 'enqueues a SubscribeJob once' do
          expect { subscribe }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).once
        end
      end

      context 'without no matching user email' do
        let(:params) { { email: 'some@email.example.com', user: user } }
        let(:user) { create(:user, accepts_email_marketing: false) }

        it 'does not enqueue a SubscribeJob (no verification needed)' do
          expect { subscribe }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(klaviyo_integration.id, kind_of(Integer)).once
        end

        it 'change user accepts_email_marketing (no verification needed)' do
          expect { subscribe }.to change { user.reload.accepts_email_marketing }.to(true)
        end
      end
    end

    describe '#verify' do
      subject(:verify) { Spree::NewsletterSubscriber.verify(token: resource.verification_token) }

      let(:resource) { create(:newsletter_subscriber, :unverified) }

      it 'enqueues a SubscribeJob once' do
        expect { verify }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(klaviyo_integration.id, resource.id).once
                             .and change { resource.reload.accepts_email_marketing }.from(false).to(true)
      end
    end

    describe '#subscribe_to_klaviyo' do
      before do
        ActiveJob::Base.queue_adapter = :test
        clear_enqueued_jobs
      end

      after { clear_enqueued_jobs }

      it 'enqueues a SubscribeJob' do
        expect {
          resource.send(:subscribe_to_klaviyo)
        }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob).with(klaviyo_integration.id, resource.id)
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
            resource.send(:subscribe_to_klaviyo)
          }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
        end
      end
    end
  end
end