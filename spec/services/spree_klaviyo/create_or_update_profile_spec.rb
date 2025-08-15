require 'spec_helper'

RSpec.describe SpreeKlaviyo::CreateOrUpdateProfile do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user) }

  context 'when klaviyo integration is exists', :vcr do
    let(:user) { create(:user, email: email, accepts_email_marketing: true) }

    let!(:klaviyo_integration) { create(:klaviyo_integration) }

    context 'when user has a profile in Klaviyo' do
      let(:email) { 'existing.user@getvendo.com' }
      let(:profile_data) do
        parsed = JSON.parse(subject.value)['data']
        parsed.is_a?(Array) ? parsed.first : parsed
      end

      it 'links an existing profile' do
        expect(subject.success?).to be(true)

        expect(user.reload.klaviyo_id).to eq(profile_data['id'])
        expect(profile_data.dig('attributes', 'email')).to eq('existing.user@getvendo.com')
      end

      context 'when email is a subaddress' do
        let(:email) { 'angelika+13@getvendo.com' }

        it 'links an existing profile' do
          expect(subject.success?).to be(true)

          expect(user.reload.klaviyo_id).to eq(profile_data['id'])
          expect(profile_data.dig('attributes', 'email')).to eq('angelika+13@getvendo.com')
        end
      end

      context 'when a guest id is provided' do
        subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user, guest_id: guest_id) }

        let(:guest_id) { 'guest-id-ghjiu786543' }

        let!(:klaviyo_integration) do
          create(
            :klaviyo_integration
          )
        end

        let(:profile_data) do
          parsed = JSON.parse(subject.value)['data']
          parsed.is_a?(Array) ? parsed.first : parsed
        end

        it 'links user and guest profiles' do
          expect(subject.success?).to be(true)

          expect(user.reload.klaviyo_id).to eq(profile_data['id'])
          expect(profile_data.dig('attributes', 'email')).to eq('existing.user@getvendo.com')
          expect(profile_data.dig('attributes', 'anonymous_id')).to eq('guest-id-ghjiu786543')
        end

        context 'when the user profile already exists' do
          let(:email) { 'existing.user@getvendo.com' }
          let(:guest_id) { 'guest-id-ghjiu786543' }

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
      let(:profile_data) do
        parsed = JSON.parse(subject.value)['data']
        parsed.is_a?(Array) ? parsed.first : parsed
      end

      let!(:klaviyo_integration) do
        create(
          :klaviyo_integration
        )
      end

      it 'creates a new profile' do
        expect(subject.success?).to be(true)

        expect(user.klaviyo_id).to eq(profile_data['id'])
        expect(profile_data.dig('attributes', 'email')).to eq(email)
      end

      context 'with a guest id' do
        subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user, guest_id: guest_id) }

        let(:email) { 'john.doe-3242343@getvendo.com' }
        let(:guest_id) { 'guest-id-asdsiu78645235343' }

        it 'creates a new profile and updates it with the guest id' do
          expect(subject.success?).to be(true)

          expect(user.klaviyo_id).to eq(profile_data['id'])
          expect(profile_data.dig('attributes', 'email')).to eq(email)
        end
      end
    end

    context 'when custom_properties are provided' do
      subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user, custom_properties: custom_properties) }
      
      let(:email) { 'custom.props@getvendo.com' }
      let(:custom_properties) { { 'Customer Tier' => 'Gold', 'Lifetime Value' => 500 } }

      it 'creates profile with custom properties' do
        expect(subject.success?).to be(true)
        profile_data = JSON.parse(subject.value)['data']
        expect(user.reload.klaviyo_id).to eq(profile_data['id'])
      end
    end

    context 'when custom_properties are invalid' do
      subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user, custom_properties: custom_properties) }
      
      let(:email) { 'invalid.props@getvendo.com' }

      context 'when custom_properties is not a Hash' do
        let(:custom_properties) { 'not-a-hash' }

        it 'skips property patching and logs a warning' do
          expect(Rails.logger).to receive(:warn).with(/Skipping properties patch/)
          expect(subject.success?).to be(true)
        end
      end

      context 'when custom_properties is nil or empty' do
        let(:custom_properties) { nil }

        it 'skips property patching gracefully' do
          expect(klaviyo_integration).not_to receive(:patch_profile_properties)
          expect(subject.success?).to be(true)
        end
      end
    end

    context 'when the user is not persisted (e.g., GuestUser from a waitlist)' do
      subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user, custom_properties: custom_properties) }
      
      # Use GuestUser PORO instead of ActiveRecord build - only with attributes it supports
      let(:user) { SpreeKlaviyo::GuestUser.new(email: "guest-user-#{Time.now.to_i}@example.com") }
      let(:custom_properties) { { 'Source' => 'Waitlist' } }

      it 'creates a Klaviyo profile but does not try to save the user' do
        # We don't want to call update_columns on an object that isn't in the DB
        expect(user).not_to receive(:update_columns)
        expect(subject.success?).to be(true)

        # The user object itself is not persisted and should not have a klaviyo_id set
        expect(user).not_to be_persisted
        expect(user.klaviyo_id).to be_nil
      end
    end
  end
end
