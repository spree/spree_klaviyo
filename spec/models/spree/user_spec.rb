require 'spec_helper'

RSpec.describe Spree.user_class, type: :model do
  describe 'Klaviyo related methods' do
    let(:user) { build(:user, klaviyo_id: klaviyo_id_value) }

    let(:klaviyo_id_value) { nil }

    describe '#klaviyo_id' do
      subject(:klaviyo_id) { user.klaviyo_id }

      context 'when not set' do
        let(:klaviyo_id_value) { nil }

        it { is_expected.to be_nil }
      end

      context 'when set' do
        let(:klaviyo_id_value) { '123' }

        it { is_expected.to eq('123') }
      end
    end

    describe '#event_payload' do
      let(:user) { create(:user) }

      after { SpreeKlaviyo::Current.reset }

      it 'does not add visitor_id when Current is unset' do
        expect(user.event_payload).not_to have_key('visitor_id')
      end

      it 'merges visitor_id from SpreeKlaviyo::Current when set' do
        SpreeKlaviyo::Current.visitor_id = 'anon-xyz'
        expect(user.event_payload['visitor_id']).to eq('anon-xyz')
      end
    end
  end
end
