require 'spec_helper'

RSpec.describe SpreeKlaviyo::BackInStockSubscriptionPresenter do
  subject { described_class.new(email: email, variant_id: variant_id).call }

  let(:email) { 'test@example.com' }
  let(:variant_id) { '123' }

  it 'returns the back in stock subscription data' do
    expect(subject).to eq(
      data: {
        type: 'back-in-stock-subscription',
        attributes: {
          channels: %w[EMAIL],
          profile: {
            data: {
              type: 'profile',
              attributes: {
                email: email
              }
            }
          }
        },
        relationships: {
          variant: {
            data: {
              type: 'catalog-variant',
              id: "$custom:::$default:::#{variant_id}"
            }
          }
        }
      }
    )
  end
end
