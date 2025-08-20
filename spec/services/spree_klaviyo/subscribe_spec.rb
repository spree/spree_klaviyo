require 'spec_helper'

describe SpreeKlaviyo::Subscribe do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, email: email, user: user, custom_properties: custom_properties) }

  let(:user) { create(:user) }
  let(:email) { user.email }
  let(:custom_properties) { {} }

  describe '#call' do
    context 'when klaviyo integration is exists' do
      let!(:klaviyo_integration) { create(:klaviyo_integration) }

      context 'when subscribe request succeeds' do
        before {
          allow(klaviyo_integration).to receive(:subscribe_user).with(email, custom_properties).and_return(Spree::ServiceModule::Result.new(true, user))
        }

        context 'when email belongs to registered user' do
          it 'returns success' do
            expect(subject.success?).to be true
          end

          context 'when user was not subscribed yet' do
            it 'marks user as subscriber' do
              expect { subject }.to change { user.reload.klaviyo_subscribed? }.from(false).to(true)
            end
          end

          context 'when user was subscriber already' do
            before { user.update(klaviyo_subscribed: true) }

            it 'does not update user as a subscriber again' do
              expect(user).not_to receive(:update).with(klaviyo_subscribed: true)
              subject
              expect(user.reload.klaviyo_subscribed?).to be true
            end
          end

          context 'with custom properties' do
            let(:custom_properties) { { zipcode: '12345', source: 'newsletter_form', age: '25' } }

            it 'sends custom properties to subscribe_user method' do
              expect(klaviyo_integration).to receive(:subscribe_user).with(email, custom_properties)
              subject
            end
          end
        end

        context 'when emails belongs to guest user' do
          let(:user) { nil }
          let(:email) { FFaker::Internet.email }

          it 'returns success' do
            expect(subject.success?).to be true
          end

          context 'with custom properties' do
            let(:custom_properties) { { zipcode: '12345', source: 'popup', interests: 'technology' } }

            it 'sends custom properties to subscribe_user method' do
              expect(klaviyo_integration).to receive(:subscribe_user).with(email, custom_properties)
              subject
            end
          end
        end
      end

      context 'when subscribe request fails' do
        it 'returns failure' do
          allow(klaviyo_integration).to receive(:subscribe_user).with(email, custom_properties).and_return(Spree::ServiceModule::Result.new(false, user))
          expect(subject.success?).to be false
        end
      end
    end

    context 'when klaviyo integration is not found' do
      let(:klaviyo_integration) { nil }

      it 'returns a failure' do
        expect(subject.success?).to be false
        expect(subject.error.value).to eq Spree.t('admin.integrations.klaviyo.not_found')
      end
    end
  end
end
