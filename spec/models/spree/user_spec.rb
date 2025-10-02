require 'spec_helper'

RSpec.describe Spree.user_class, type: :model do
  include ActiveJob::TestHelper

  describe 'Klaviyo' do
    let(:user) { build(:user) }
    let!(:klaviyo_integration) { create(:klaviyo_integration) }
  end
end
