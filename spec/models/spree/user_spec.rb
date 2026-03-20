require 'spec_helper'

RSpec.describe Spree.user_class, type: :model do
  describe 'Klaviyo related methods' do
    let(:user) { build(:user, klaviyo_id: klaviyo_id_value, klaviyo_visitor_id: klaviyo_visitor_id_value) }

    let(:klaviyo_id_value) { nil }
    let(:klaviyo_visitor_id_value) { nil }

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

    describe '#klaviyo_visitor_id' do
      subject(:klaviyo_visitor_id) { user.klaviyo_visitor_id }

      context 'when not set' do
        it { is_expected.to be_nil }
      end

      context 'when set' do
        let(:klaviyo_visitor_id_value) { '123' }

        it { is_expected.to eq('123') }
      end
    end
  end
end
