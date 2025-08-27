require 'spec_helper'

RSpec.describe SpreeKlaviyo::CreateOrUpdateProfile do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user) }

  context 'when klaviyo integration is exists', :vcr do
    let(:user) { create(:user, email: email, accepts_email_marketing: true) }

    let!(:klaviyo_integration) { create(:klaviyo_integration, preferred_klaviyo_private_api_key: 'pk_123') }

    context 'when user has a profile in Klaviyo' do
      let(:email) { 'existing.user@getvendo.com' }
      let(:profile_data) { JSON.parse(subject.value)['data'][0] }

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

        let(:profile_data) { JSON.parse(subject.value)['data'] }

        it 'links user and guest profiles' do
          expect(subject.success?).to be(true)

          expect(user.reload.klaviyo_id).to eq(profile_data['id'])
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

  context 'when creating guest-only profiles (no user)', :vcr do
    let!(:klaviyo_integration) do 
      create(:klaviyo_integration, preferred_klaviyo_public_api_key: 'RZUvUQ', preferred_klaviyo_private_api_key: 'pk_8d2bcc4570678967f4d3756fed304430eb', preferred_default_newsletter_list_id: 'XLUG56')
    end
    let(:custom_properties) { { 'source' => 'newsletter', 'zip_code' => '12345' } }
  
    context 'with guest_id' do
      let(:guest_id) { 'guest-spec-with-props-001' }
      subject do
        described_class.call(
          klaviyo_integration: klaviyo_integration,
          guest_id: guest_id,
          custom_properties: custom_properties
        )
      end
  
      it 'creates a guest profile successfully', vcr: { cassette_name: 'create_guest_profile_with_properties' } do
        expect(subject.success?).to be(true)
        
        profile_data = JSON.parse(subject.value)['data']
        expect(profile_data.dig('attributes', 'anonymous_id')).to eq(guest_id)
        
        if profile_data.dig('attributes', 'properties')
          expect(profile_data.dig('attributes', 'properties')).to include(custom_properties)
        end
      end
    end
  
    context 'with no email id and no guest_id' do
      subject { described_class.call(klaviyo_integration: klaviyo_integration, custom_properties: custom_properties) }
  
      it 'returns failure with appropriate error message' do
        expect(subject.success?).to be(false)
        expect(subject.error.value).to eq('No identifier (guest_id) provided')
      end
    end
  
    context 'with no custom properties' do
      let(:guest_id) { 'guest-spec-no-props-001' }
      subject { described_class.call(klaviyo_integration: klaviyo_integration, guest_id: guest_id) }
      
      it 'creates a guest profile without custom properties', vcr: { cassette_name: 'create_guest_profile_without_properties' } do
        expect(subject.success?).to be(true)
        
        profile_data = JSON.parse(subject.value)['data']
        expect(profile_data.dig('attributes', 'anonymous_id')).to eq(guest_id)
        expect(profile_data.dig('attributes', 'properties')).to eq({})
      end
    end
  end

  context 'when passing custom_properties (user present)', :vcr do
    let(:user) { create(:user, email: "john.doe+test-props@getvendo.com") }
    let!(:klaviyo_integration) do
      create(:klaviyo_integration, preferred_klaviyo_public_api_key: 'RZUvUQ', preferred_klaviyo_private_api_key: 'pk_8d2bcc4570678967f4d3756fed304430eb', preferred_default_newsletter_list_id: 'XLUG56')
    end
    
    let(:custom_properties) { { 'unsupported_zip_code' => '99999', 'source' => 'test' } }
  
    context 'and user already has klaviyo_id' do
      subject do
        described_class.call(
          klaviyo_integration: klaviyo_integration,
          user: user,
          custom_properties: custom_properties
        )
      end
      
      it 'updates profile successfully', vcr: { cassette_name: 'update_profile_with_properties' } do
        fetch_result = SpreeKlaviyo::FetchProfile.call(klaviyo_integration: klaviyo_integration, user: user)
        if fetch_result.success?
          klaviyo_id = JSON.parse(fetch_result.value).dig('data', 0, 'id')
          user.update!(private_metadata: user.private_metadata.merge('klaviyo_id' => klaviyo_id)) if klaviyo_id.present?
        end

        expect(subject.success?).to be(true), -> { subject.error&.value || subject.value }
        
        profile_data = JSON.parse(subject.value)['data']
        if profile_data.dig('attributes', 'properties')
          expect(profile_data.dig('attributes', 'properties')).to include(custom_properties)
        end
      end
    end
  
    context 'and user has no klaviyo_id' do
      subject do
        described_class.call(
          klaviyo_integration: klaviyo_integration,
          user: user,
          custom_properties: custom_properties
        )
      end
      
      it 'creates or links and then updates successfully', vcr: { cassette_name: 'create_and_update_profile_with_properties' } do
        expect(subject.success?).to be(true), -> { subject.error&.value || subject.value }
        
        expect(user.reload.klaviyo_id).to be_present
        
        profile_data = JSON.parse(subject.value)['data']
        expect(profile_data.dig('attributes', 'email')).to eq(user.email)
      end
    end
  end
end
