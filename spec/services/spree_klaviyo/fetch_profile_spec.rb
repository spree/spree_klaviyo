require 'spec_helper'

describe SpreeKlaviyo::FetchProfile do
  subject { described_class.call(klaviyo_integration: klaviyo_integration, user: user) }

  let(:user) do
    user_attributes = {}
    user_attributes[:accepts_email_marketing] = true if Spree.user_class.new.respond_to?(:accepts_email_marketing=)
    create(:user, user_attributes)
  end

  describe '#call' do
    context 'when klaviyo integration is exists' do
      let!(:klaviyo_integration) { create(:klaviyo_integration) }

      context 'when user has klaviyo_id' do
        before { user.update(klaviyo_id: '123') }

        it 'doest not make request and returns success' do
          expect_any_instance_of(Spree::Integrations::Klaviyo).not_to receive(:fetch_profile)
          expect(subject.success?).to be true
        end
      end

      context 'when user does not have klaviyo_id' do
        before do
          allow_any_instance_of(Spree::Integrations::Klaviyo)
            .to receive(:fetch_profile)
            .with({ email: user.email })
            .and_return(Spree::ServiceModule::Result.new(true, { data: [{ id: '123' }] }.to_json))
        end

        context 'when user has profile in Klaviyo' do
          it 'returns success' do
            expect(subject.success?).to be true
          end

          it 'assigns fetched klaviyo_id' do
            expect { subject }.to change { user.reload.klaviyo_id }.from(nil).to('123')
          end
        end

        context 'when user does not have profile in klaviyo' do
          before do
            allow_any_instance_of(Spree::Integrations::Klaviyo)
              .to receive(:fetch_profile)
              .with({ email: user.email })
              .and_return(Spree::ServiceModule::Result.new(false, user.email))
          end

          it 'returns failure' do
            expect(subject.success?).to be false
          end
        end
      end

      context 'when request fails' do
        it 'returns failure' do
          allow_any_instance_of(Spree::Integrations::Klaviyo).to receive(:fetch_profile).with({ email: user.email }).and_return(Spree::ServiceModule::Result.new(
                                                                                                                                  false, user.email
                                                                                                                                ))
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
