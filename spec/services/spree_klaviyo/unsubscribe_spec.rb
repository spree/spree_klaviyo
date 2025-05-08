require 'spec_helper'

describe SpreeKlaviyo::Unsubscribe do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, email: email, user: user) }

  let(:user) { create(:user) }
  let(:email) { user.email }

  describe '#call' do
    context 'when klaviyo integration exists' do
      let!(:klaviyo_integration) { create(:klaviyo_integration) }

      context 'when unsubscribe request succeeds' do
        before do
          allow_any_instance_of(Spree::Integrations::Klaviyo)
            .to receive(:unsubscribe_user).with(email)
            .and_return(Spree::ServiceModule::Result.new(true, user))
        end

        context 'when email belongs to registered user' do
          it 'returns success' do
            expect(subject.success?).to be true
          end

          context 'when user was already subscribed' do
            before { user.update(klaviyo_subscribed: true) }

            it 'marks user as not a subscriber' do
              expect { subject }.to change { user.reload.klaviyo_subscribed? }.from(true).to(false)
            end
          end

          context 'when user was not a subscriber already' do
            before { user.update(klaviyo_subscribed: false) }

            it 'does not update user as not a subscriber again' do
              expect(user).not_to receive(:update).with(klaviyo_subscribed: false)
              subject
              expect(user.reload.klaviyo_subscribed?).to be false
            end
          end
        end

        context 'when emails belongs to guest user' do
          let(:user) { nil }
          let(:email) { FFaker::Internet.email }

          it 'returns success' do
            expect(subject.success?).to be true
          end
        end
      end

      context 'when subscribe request fails' do
        it 'returns failure' do
          allow_any_instance_of(Spree::Integrations::Klaviyo)
            .to receive(:unsubscribe_user).with(email)
            .and_return(Spree::ServiceModule::Result.new(false, user))

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
