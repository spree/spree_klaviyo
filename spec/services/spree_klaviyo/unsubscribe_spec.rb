require 'spec_helper'

describe SpreeKlaviyo::Unsubscribe do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, email: email) }

  let(:email) { FFaker::Internet.email }

  describe '#call' do
    context 'when klaviyo integration exists' do
      let!(:klaviyo_integration) { create(:klaviyo_integration) }

      context 'when unsubscribe request succeeds' do
        before do
          allow_any_instance_of(Spree::Integrations::Klaviyo)
            .to receive(:unsubscribe_user).with(email)
            .and_return(Spree::ServiceModule::Result.new(true, 'response'))
        end

        context 'when newsletter subscriber exists' do
          before do
            create(:newsletter_subscriber, email: email)
          end

          it 'destroys newsletter subscriber' do
            expect { subject }.to change { Spree::NewsletterSubscriber.count }.by(-1)
          end
        end

        context 'when email belongs to registered user' do
          it 'returns success' do
            expect(subject.success?).to be true
          end
        end

        context 'when emails belongs to guest user' do
          let(:user) { nil }

          it 'returns success' do
            expect(subject.success?).to be true
          end
        end
      end

      context 'when subscribe request fails' do
        it 'returns failure' do
          allow_any_instance_of(Spree::Integrations::Klaviyo)
            .to receive(:unsubscribe_user).with(email)
            .and_return(Spree::ServiceModule::Result.new(false, 'response'))

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
