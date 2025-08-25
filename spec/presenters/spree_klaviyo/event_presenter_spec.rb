require 'spec_helper'

RSpec.describe SpreeKlaviyo::EventPresenter do
  subject { described_class.new(integration: integration, event: event, resource: resource, email: email, guest_id: guest_id).call }

  let(:store) { Spree::Store.default }
  let(:integration) { create(:klaviyo_integration, store: store) }
  let(:event) { 'Unsupported Zipcode Attempt' }
  let(:resource) { { foo: 'bar' } }
  let(:email) { nil }
  let(:guest_id) { 'guest-1' }

  describe '#call' do
    it 'uses guest profile when email is nil' do
      expect(subject[:data][:attributes][:profile][:data][:attributes][:anonymous_id]).to eq('guest-1')
      expect(subject[:data][:attributes][:profile][:data][:attributes]).not_to have_key(:email)
    end

    context 'when email is present' do
      let(:email) { 'user@example.com' }

      it 'uses email profile when email is present' do
        expect(subject[:data][:attributes][:profile][:data][:attributes][:anonymous_id]).to eq('guest-1')
        expect(subject[:data][:attributes][:profile][:data][:attributes][:email]).to eq('user@example.com')
      end
    end

    it 'passes hash resource as properties' do
      expect(subject[:data][:attributes][:properties]).to eq(resource)
    end
  end
end
