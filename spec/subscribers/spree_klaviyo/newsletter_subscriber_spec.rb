require 'spec_helper'

RSpec.describe SpreeKlaviyo::NewsletterSubscriber do
  subject(:invoke_subscriber) { described_class.new.call(event) }
  let(:store) { Spree::Store.default }
  let(:newsletter_subscriber) { create(:newsletter_subscriber) }
  let!(:klaviyo_integration) { create(:klaviyo_integration, store: store) }

  around do |example|
    perform_enqueued_jobs(only: Spree::Events::SubscriberJob) { example.run }
  end

  describe '#newsletter_subscriber.created event' do
    let(:email) { 'customer@example.com' }

    it 'enqueues SubscribeJob when a newsletter subscriber is created via checkout' do
      expect {
        Spree::Newsletter::Subscribe.new(email: email).call
      }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
    end

    it 'does not enqueue SubscribeJob when subscriber already exists' do
      create(:newsletter_subscriber, email: email)

      expect {
        Spree::Newsletter::Subscribe.new(email: email).call
      }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue SubscribeJob' do
        expect {
          Spree::Newsletter::Subscribe.new(email: email).call
        }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
      end
    end
  end

  describe '#newsletter_subscriber.deleted event' do
    let!(:existing_subscriber) { create(:newsletter_subscriber) }

    it 'enqueues UnsubscribeJob when a newsletter subscriber is destroyed' do
      expect {
        existing_subscriber.destroy!
      }.to have_enqueued_job(SpreeKlaviyo::UnsubscribeJob)
    end

    context 'without klaviyo integration' do
      before { klaviyo_integration.destroy! }

      it 'does not enqueue UnsubscribeJob' do
        expect {
          existing_subscriber.destroy!
        }.not_to have_enqueued_job(SpreeKlaviyo::UnsubscribeJob)
      end
    end
  end
end
