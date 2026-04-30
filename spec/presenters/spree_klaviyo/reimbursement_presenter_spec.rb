require 'spec_helper'

RSpec.describe SpreeKlaviyo::ReimbursementPresenter do
  subject { described_class.new(reimbursement: reimbursement).call }

  let(:reimbursement) { create(:reimbursement) }
  let(:order) { reimbursement.order }
  let(:store) { order.store }
  let(:return_item) { reimbursement.return_items.first }

  it 'returns the reimbursement data' do
    result = subject

    expect(result[:customer_name]).to eq(order.name)
    expect(result[:email]).to eq(order.email)
    expect(result[:order_number]).to eq(order.number)
    expect(result[:store_name]).to eq(store.name)
    expect(result[:total]).to eq(reimbursement.total.to_f)
    expect(result[:display_total]).to eq(reimbursement.display_total.to_s)
    expect(result[:number]).to eq(reimbursement.number)
    expect(result[:reimbursement_id]).to eq(reimbursement.id)
    expect(result[:return_items].length).to eq(reimbursement.return_items.count)
    expect(result[:return_items].first[:name]).to eq(return_item.variant.name)
    expect(result[:return_items].first[:sku]).to eq(return_item.variant.sku)
    expect(result[:exchange_items]).to eq([])
  end
end
