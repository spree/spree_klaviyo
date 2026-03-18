require 'spec_helper'

describe SpreeKlaviyo::Unsubscribe do
  subject(:call) { described_class.call(klaviyo_integration: klaviyo_integration, email: email, user: user) }

  let(:email) { 'unsubscribe-user@example.com' }
  let(:user) { create(:user, email: email, accepts_email_marketing: true, klaviyo_subscribed: klaviyo_subscribed) }
  let(:klaviyo_subscribed) { true }
  let(:klaviyo_integration) { create(:klaviyo_integration) }

  context 'when unsubscribe request succeeds' do
    context 'when email belongs to registered user' do
      it 'returns success' do
        VCR.use_cassette('services/spree_klaviyo/unsubscribe/success_for_registered_user') do
          expect(call).to be_success
        end
      end

      context 'when user was subscribed' do
        let(:klaviyo_subscribed) { true }

        it 'marks user as not a subscriber' do
          VCR.use_cassette('services/spree_klaviyo/unsubscribe/success_for_registered_user') do
            expect { call }.to change { user.reload.klaviyo_subscribed? }.from(true).to(false)
          end
        end
      end

      context 'when user was not subscribed' do
        let(:klaviyo_subscribed) { false }

        it 'does not update user as not a subscriber again' do
          VCR.use_cassette('services/spree_klaviyo/unsubscribe/success_for_registered_user') do
            expect(call).to be_success
          end
        end
      end
    end

    context 'when emails belongs to guest user' do
      let(:user) { nil }
      let(:email) { 'guest@example.com' }

      it 'returns success' do
        VCR.use_cassette('services/spree_klaviyo/unsubscribe/success_for_guest_user') do
          expect(call).to be_success
        end
      end
    end
  end

  context 'when unsubscribe request fails' do
    let(:klaviyo_integration) { create(:klaviyo_integration, preferred_default_newsletter_list_id: 'invalid-list-id') }

    it 'returns failure' do
      VCR.use_cassette('services/spree_klaviyo/unsubscribe/failure') do
        expect(call).to be_failure
      end
    end
  end
end
