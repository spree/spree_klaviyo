require 'spec_helper'

RSpec.describe SpreeKlaviyo::CreateOrUpdateProfile do
  subject(:call) { described_class.call(klaviyo_integration: klaviyo_integration, user: user) }

  let(:user) { create(:user, email: email, first_name: 'Cami', last_name: 'Leffler', accepts_email_marketing: true, klaviyo_id: nil) }

  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:profile_data) { JSON.parse(call_with_request.value)['data'] }

  context 'when user has a profile in Klaviyo' do
    let(:email) { 'existing.user@getvendo.com' }
    let(:id_from_response) { '01JX2SMZ5B8MA1GY0HS4PHB35S' }

    it 'updates user klaviyo_id' do
      VCR.use_cassette('services/spree_klaviyo/create_or_update_profile/success_with_exisitng_profile') do
        expect { call }.to change(user, :klaviyo_id).from(nil).to(id_from_response)
        expect(call).to be_success
      end
    end

    it 'links an existing profile' do
      VCR.use_cassette('services/spree_klaviyo/create_or_update_profile/success_with_exisitng_profile') do
        expect(JSON.parse(call.value).dig('data', 'attributes', 'email')).to eq('existing.user@getvendo.com')
      end
    end
  end

  context 'when user does not have profile in klaviyo' do
    let(:email) { 'john.doe-578423@getvendo.com' }
    let(:id_from_response) { '01KKY2N04K6W3SKM6QP24PSW56' }

    it 'assigned klaviyo_id from newly created profile to user' do
      VCR.use_cassette('services/spree_klaviyo/create_or_update_profile/success_with_new_profile') do
        expect { call }.to change(user, :klaviyo_id).from(nil).to(id_from_response)
        expect(call).to be_success
      end
    end
  end
end
