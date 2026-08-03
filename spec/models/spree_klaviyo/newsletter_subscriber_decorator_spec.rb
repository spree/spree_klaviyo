require 'spec_helper'

RSpec.describe SpreeKlaviyo::NewsletterSubscriberDecorator do
  let(:store) { Spree::Store.default }
  let(:email) { 'customer@example.com' }

  context 'with an active Klaviyo integration for the store' do
    before { create(:klaviyo_integration, store: store) }

    it 'verifies the subscriber immediately on create' do
      subscriber = create(:newsletter_subscriber, email: email, store: store)

      expect(subscriber).to be_verified
    end

    it 'clears the verification token' do
      subscriber = create(:newsletter_subscriber, email: email, store: store)

      expect(subscriber.verification_token).to be_nil
    end

    it 'skips the Spree double opt-in request so no confirmation email is sent' do
      allow(Spree::Events).to receive(:publish).and_call_original

      Spree::Newsletter::Subscribe.new(email: email, current_store: store).call

      expect(Spree::Events).not_to have_received(:publish).with(
        'newsletter_subscriber.subscription_requested', anything, anything
      )
    end
  end

  context 'when the Klaviyo integration is inactive' do
    before { create(:klaviyo_integration, store: store, active: false) }

    it 'leaves the subscriber unverified' do
      subscriber = create(:newsletter_subscriber, email: email, store: store)

      expect(subscriber).not_to be_verified
    end
  end

  context 'without a Klaviyo integration for the store' do
    it 'leaves the subscriber unverified so Spree double opt-in proceeds' do
      subscriber = create(:newsletter_subscriber, email: email, store: store)

      expect(subscriber).not_to be_verified
    end

    it 'publishes the subscription_requested event' do
      allow(Spree::Events).to receive(:publish).and_call_original

      Spree::Newsletter::Subscribe.new(email: email, current_store: store).call

      expect(Spree::Events).to have_received(:publish).with(
        'newsletter_subscriber.subscription_requested', anything, anything
      )
    end
  end

  context 'when the only Klaviyo integration belongs to another store' do
    before { create(:klaviyo_integration, store: create(:store)) }

    it 'leaves the subscriber unverified' do
      subscriber = create(:newsletter_subscriber, email: email, store: store)

      expect(subscriber).not_to be_verified
    end
  end
end
