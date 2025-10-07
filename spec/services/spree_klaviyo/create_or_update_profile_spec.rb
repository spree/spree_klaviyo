require 'spec_helper'

RSpec.describe SpreeKlaviyo::CreateOrUpdateProfile do
  subject { described_class.call(**params) }

  let(:default_params) { { klaviyo_integration: klaviyo_integration, user: user } }
  let(:params) { default_params }

  context 'when klaviyo integration is exists', :vcr do
    let(:user) { create(:user, email: email, accepts_email_marketing: true) }

    let!(:klaviyo_integration) { create(:klaviyo_integration, preferred_klaviyo_private_api_key: 'pk_123') }

    context 'when user has a profile in Klaviyo' do
      let(:email) { 'existing.user@getvendo.com' }
      let(:profile_data) { JSON.parse(subject.value)['data'][0] }

      it 'links an existing profile' do
        expect(subject.success?).to be(true)

        expect(user.get_metafield('klaviyo.id').value).to eq(profile_data['id'])
        expect(profile_data.dig('attributes', 'email')).to eq('existing.user@getvendo.com')
      end

      context 'when email is a subaddress' do
        let(:email) { 'angelika+13@getvendo.com' }

        it 'links an existing profile' do
          expect(subject.success?).to be(true)

          expect(user.get_metafield('klaviyo.id').value).to eq(profile_data['id'])
          expect(profile_data.dig('attributes', 'email')).to eq('angelika+13@getvendo.com')
        end
      end

      context 'when a guest id is provided' do
        let(:params) { default_params.merge(guest_id: guest_id) }

        let(:guest_id) { 'guest-id-ghjiu786543' }

        let!(:klaviyo_integration) do
          create(
            :klaviyo_integration
          )
        end

        let(:profile_data) { JSON.parse(subject.value)['data'] }

        it 'links user and guest profiles' do
          expect(subject.success?).to be(true)

          expect(user.get_metafield('klaviyo.id').value).to eq(profile_data['id'])
          expect(profile_data.dig('attributes', 'email')).to eq('existing.user@getvendo.com')
          expect(profile_data.dig('attributes', 'anonymous_id')).to eq('guest-id-ghjiu786543')
        end

        context 'when the user profile already exists' do
          let(:email) { 'john.doe+track-guest-test-1@getvendo.com' }
          let(:guest_id) { 'guest-id-gasdasdsiu786543' }

          it 'updates the user profile with the guest id' do
            expect(subject.success?).to be(true)

            expect(profile_data.dig('attributes', 'email')).to eq(email)
            expect(profile_data.dig('attributes', 'anonymous_id')).to eq(guest_id)
          end
        end
      end
    end

    context 'when user does not have profile in klaviyo' do
      let(:email) { 'john.doe-578423@getvendo.com' }
      let(:profile_data) { JSON.parse(subject.value)['data'] }

      let!(:klaviyo_integration) do
        create(
          :klaviyo_integration
        )
      end

      it 'creates a new profile' do
        expect(subject.success?).to be(true)

        expect(user.get_metafield('klaviyo.id').value).to eq(profile_data['id'])
        expect(profile_data.dig('attributes', 'email')).to eq(email)
      end

      context 'with a guest id' do
        let(:params) { default_params.merge(guest_id: guest_id) }

        let(:email) { 'john.doe-3242343@getvendo.com' }
        let(:guest_id) { 'guest-id-asdsiu78645235343' }

        it 'creates a new profile and updates it with the guest id' do
          expect(subject.success?).to be(true)

          expect(user.get_metafield('klaviyo.id').value).to eq(profile_data['id'])
          expect(profile_data.dig('attributes', 'email')).to eq(email)
        end
      end
    end
  end

  context 'when klaviyo integration is not found' do
    let(:user) { create(:user, accepts_email_marketing: true) }
    let(:klaviyo_integration) { nil }

    it 'returns a failure' do
      expect(subject.success?).to be(false)
      expect(subject.error.value).to eq(Spree.t('admin.integrations.klaviyo.not_found'))
    end
  end
end
