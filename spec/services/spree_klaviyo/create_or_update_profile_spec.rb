require 'spec_helper'

RSpec.describe SpreeKlaviyo::CreateOrUpdateProfile do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user) }

  let(:custom_properties) { { 'Waitlist Zipcode' => '99999' } }

  # Stub update_columns to avoid errors in tests where the column might not exist
  before do
    allow_any_instance_of(::Spree.user_class).to receive(:update_columns) do |instance, attrs|
      attrs.each { |key, value| instance.send("#{key}=", value) if instance.respond_to?("#{key}=") }
      true
    end
  end

  context 'when klaviyo integration is exists', :vcr do
    let(:user) { create(:user, email: email, accepts_email_marketing: true) }

    let!(:klaviyo_integration) { create(:klaviyo_integration, preferred_klaviyo_private_api_key: 'pk_123') }

    context 'when user has a profile in Klaviyo' do
      let(:email) { 'existing.user@getvendo.com' }
      let(:profile_data) { JSON.parse(subject.value)['data'][0] }

      it 'links an existing profile' do
        expect(subject.success?).to be(true)

        expect(user.klaviyo_id).to eq(profile_data['id'])
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

        let(:profile_data) { JSON.parse(subject.value)['data'] }

        it 'links user and guest profiles' do
          expect(subject.success?).to be(true)

          expect(user.klaviyo_id).to eq(profile_data['id'])
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
  end

  context 'when klaviyo integration is not found' do
    let(:user) { create(:user, accepts_email_marketing: true) }
    let(:klaviyo_integration) { nil }

    it 'returns a failure' do
      expect(subject.success?).to be(false)
      expect(subject.error.value).to eq(Spree.t('admin.integrations.klaviyo.not_found'))
    end
  end

  context 'when user record is not persisted' do
    let(:user) { build(:user, email: 'anon+waitlist@example.com') }

    let(:klaviyo_integration) { build_stubbed(:klaviyo_integration) }

    before do
      # Force FetchProfile to return failure so the service tries to create a profile.
      allow(SpreeKlaviyo::FetchProfile).to receive(:call).and_return(
        Spree::ServiceModule::Result.new(false, user.email)
      )

      # Stub create_profile to succeed and return a minimal Klaviyo payload.
      payload = { data: { id: '01TESTPROFILEID' } }.to_json
      allow(klaviyo_integration).to receive(:create_profile).and_return(
        Spree::ServiceModule::Result.new(true, payload)
      )
    end

    it 'returns success and does not persist the user' do
      result = described_class.call(klaviyo_integration: klaviyo_integration, user: user)

      expect(result.success?).to be(true)
      expect(user).not_to be_persisted
      expect(user.klaviyo_id).to be_nil
    end
  end

  context 'when user is persisted' do
    let(:klaviyo_integration) { create(:klaviyo_integration) }
    let(:user) { create(:user, email: 'test@example.com', klaviyo_id: 'klaviyo-123') }

    let(:service_result) { Spree::ServiceModule::Result.new(true, '{}') }

    let(:client_double) { instance_double('SpreeKlaviyo::Klaviyo::Client') }

    before do
      # Stub FetchProfile to avoid VCR issues
      allow(SpreeKlaviyo::FetchProfile).to receive(:call).and_return(
        Spree::ServiceModule::Result.new(false, user.email)
      )

      allow(klaviyo_integration).to receive(:update_profile).and_return(service_result)
      allow(klaviyo_integration).to receive(:create_profile).and_return(service_result)

      allow(klaviyo_integration).to receive(:send).with(:client).and_return(client_double)
      allow(client_double).to receive(:patch_request).and_return(service_result)
    end

    it 'patches profile properties with provided custom properties' do
      expect(client_double).to receive(:patch_request).with(
        "profiles/#{user.klaviyo_id}/",
        hash_including(data: hash_including(attributes: hash_including(properties: custom_properties)))
      ).and_return(service_result)

      described_class.call(klaviyo_integration: klaviyo_integration, user: user, custom_properties: custom_properties)
    end
  end

  context 'when user is a guest (not persisted)' do
    let(:klaviyo_integration) { create(:klaviyo_integration) }
    let(:user) { build(:user, email: 'guest@example.com', klaviyo_id: nil) }

    let(:klaviyo_response_payload) { { data: { id: 'klaviyo-guest-999' } }.to_json }
    let(:service_result) { Spree::ServiceModule::Result.new(true, klaviyo_response_payload) }

    let(:client_double) { instance_double('SpreeKlaviyo::Klaviyo::Client') }

    before do
      # Stub FetchProfile to avoid VCR issues
      allow(SpreeKlaviyo::FetchProfile).to receive(:call).and_return(
        Spree::ServiceModule::Result.new(false, user.email)
      )

      allow(klaviyo_integration).to receive(:update_profile).and_return(service_result)
      allow(klaviyo_integration).to receive(:create_profile).and_return(service_result)

      allow(klaviyo_integration).to receive(:send).with(:client).and_return(client_double)
      allow(client_double).to receive(:patch_request).and_return(service_result)
    end

    it 'does not attempt to persist klaviyo_id' do
      expect(user).not_to receive(:update_columns)

      described_class.call(klaviyo_integration: klaviyo_integration, user: user, custom_properties: custom_properties)
    end

    it 'extracts klaviyo_id from response and patches profile properties' do
      expect(client_double).to receive(:patch_request).with(
        'profiles/klaviyo-guest-999/',
        hash_including(data: hash_including(id: 'klaviyo-guest-999', attributes: hash_including(properties: custom_properties)))
      ).and_return(service_result)

      described_class.call(klaviyo_integration: klaviyo_integration, user: user, custom_properties: custom_properties)
    end
  end
end
