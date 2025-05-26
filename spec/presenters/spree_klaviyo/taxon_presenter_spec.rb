require 'spec_helper'

RSpec.describe SpreeKlaviyo::TaxonPresenter do
  subject { described_class.new(taxon: taxon).call }

  let(:taxon) { create(:taxon) }
  let(:store) { taxon.store }

  it 'returns the taxon data' do
    expect(subject).to eq(
      name: taxon.pretty_name,
      image_url: '',
      url: "http://#{store.url}:3000/t/#{taxon.permalink}"
    )
  end
end
