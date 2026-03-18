require 'spec_helper'

describe SpreeKlaviyo::Subscribe do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, email: email, user: user) }

  let(:user) { create(:user, email: 'user@example.com') }
  let(:email) { user.email }
  let(:klaviyo_integration) { create(:klaviyo_integration) }

  context 'when subscribe request succeeds' do
    context 'when email belongs to registered user' do
      it 'returns success' do
        VCR.use_cassette('services/spree_klaviyo/subscribe/success_for_registered_user') do
          expect(subject).to be_success
        end
      end

      context 'when user was not subscribed yet' do
        it 'marks user as subscriber' do
          VCR.use_cassette('services/spree_klaviyo/subscribe/success_for_registered_user') do
            expect { subject }.to change { user.reload.klaviyo_subscribed? }.from(false).to(true)
          end
        end
      end
    end

    context 'when emails belongs to guest user' do
      let(:user) { nil }
      let(:email) { 'guest@example.com' }

      it 'returns success' do
        VCR.use_cassette('services/spree_klaviyo/subscribe/success_for_guest_user') do
          expect(subject).to be_success
        end
      end
    end
  end

  context 'when subscribe request fails' do
    let(:klaviyo_integration) { create(:klaviyo_integration, preferred_default_newsletter_list_id: 'invalid-list-id') }

    it 'returns failure' do
      VCR.use_cassette('services/spree_klaviyo/subscribe/failure', record: :new_episodes) do
        expect(subject).to be_failure
      end
    end
  end
end
