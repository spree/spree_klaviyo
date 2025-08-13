require 'spec_helper'

RSpec.describe SpreeKlaviyo::CreateOrUpdateProfile do
  describe '#call' do
    subject do
      described_class.call(
        klaviyo_integration: klaviyo_integration,
        user: user,
        custom_properties: custom_properties
      )
    end

    let(:user) { create(:user, email: 'test@example.com', klaviyo_id: 'klaviyo-123') }
    let(:klaviyo_integration) { create(:klaviyo_integration) }
    let(:custom_properties) { { 'Waitlist Zipcode' => '99999' } }

    let(:service_result) { Spree::ServiceModule::Result.new(true, '{}') }

    let(:client_double) { instance_double('SpreeKlaviyo::Klaviyo::Client') }

    before do
      allow(klaviyo_integration).to receive(:update_profile).and_return(service_result)
      allow(klaviyo_integration).to receive(:create_profile).and_return(service_result)

      allow(klaviyo_integration).to receive(:send).with(:client).and_return(client_double)
      # Default stub; expectation will refine later
      allow(client_double).to receive(:patch_request).and_return(service_result)
    end

    it 'sends a patch request with the provided custom properties' do
      expect(client_double).to receive(:patch_request).with(
        "profiles/#{user.klaviyo_id}/",
        hash_including(data: hash_including(attributes: hash_including(properties: custom_properties)))
      ).and_return(service_result)

      subject
    end

    it 'returns a success result' do
      expect(subject.success?).to be(true)
    end
  end
end
