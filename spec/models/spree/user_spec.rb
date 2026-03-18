require 'spec_helper'

RSpec.describe Spree.user_class, type: :model do
  describe 'Klaviyo' do
    let(:user) { build(:user) }

    describe '#klaviyo_subscribed?' do
      it 'returns false by default' do
        expect(user.klaviyo_subscribed?).to be(false)
      end

      it 'returns true when set' do
        user.klaviyo_subscribed = true
        expect(user.klaviyo_subscribed?).to be(true)
      end
    end
  end
end
