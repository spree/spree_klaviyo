require 'spec_helper'

RSpec.describe SpreeKlaviyo::UserPresenter do
  subject { described_class.new(email: email, address: address, user: user, guest_id: guest_id, custom_properties: custom_properties).call }

  let(:email) { 'guest@example.com' }
  let(:address) { nil }
  let(:user) { nil }
  let(:guest_id) { nil }
  let(:custom_properties) { {} }

  describe '#call' do
    context 'when guest with email only and no custom properties' do
      it 'builds profile attributes without properties key' do
        expect(subject[:data][:type]).to eq('profile')
        expect(subject[:data][:attributes][:email]).to eq('guest@example.com')
        expect(subject[:data][:attributes][:anonymous_id]).to be_nil
        expect(subject[:data][:attributes]).not_to have_key(:properties)
      end
    end

    context 'when custom properties are provided' do
      let(:custom_properties) { { 'unsupported_zip_code' => '99999' } }

      it 'includes properties in attributes' do
        expect(subject[:data][:attributes][:properties]).to eq({ 'unsupported_zip_code' => '99999' })
      end
    end

    context 'when user has klaviyo_id' do
      let(:user) { create(:user) }

      it 'merges klaviyo id at the top level' do
        user.update!(private_metadata: user.private_metadata.merge('klaviyo_id' => 'klv_123'))

        expect(subject[:data][:id]).to eq('klv_123')
        expect(subject[:data][:attributes][:email]).to eq(user.email)
      end
    end
  end
end
