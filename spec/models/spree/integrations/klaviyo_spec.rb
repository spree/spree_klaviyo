# == Schema Information
#
# Table name: spree_integrations
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(FALSE), not null
#  preferences :text
#  type        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  store_id    :bigint           not null
#  tenant_id   :bigint           not null
#
require 'spec_helper'

describe Spree::Integrations::Klaviyo, type: :model do
  let(:klaviyo_integration) { create(:klaviyo_integration) }
  let(:store) { Spree::Store.default }

  describe 'validations' do
    it 'validates presence of klaviyo_public_api_key' do
      klaviyo_integration.klaviyo_public_api_key = nil
      expect(klaviyo_integration).not_to be_valid
    end

    it 'validates presence of klaviyo_private_api_key' do
      klaviyo_integration.klaviyo_private_api_key = nil
      expect(klaviyo_integration).not_to be_valid
    end

    it 'validates presence of default_newsletter_list_id' do
      klaviyo_integration.default_newsletter_list_id = nil
      expect(klaviyo_integration).not_to be_valid
    end
  end

  describe '#subscribe_user' do
    subject { klaviyo_integration.subscribe_user(email) }

    let(:klaviyo_integration) do
      create(
        :klaviyo_integration,
        klaviyo_public_api_key: 'RZUvUQ',
        klaviyo_private_api_key: 'pk_8d2bcc4570678967f4d3756fed304430eb',
        default_newsletter_list_id: 'XLUG56'
      )
    end
    let(:email) { 'example@email.com' }

    context 'when email is valid' do
      it 'subscribes user' do
        VCR.use_cassette('klaviyo/subscribing_user/success') do
          expect(subject.success?).to be true
        end
      end
    end

    context 'when email has wrong format' do
      let(:email) { 'wrong-email' }

      it 'returns failure' do
        VCR.use_cassette('klaviyo/subscribing_user/failure') do
          expect(subject.success?).to be false
        end
      end

      it 'sends error to Rails.error' do
        VCR.use_cassette('klaviyo/subscribing_user/failure') do
          expect(Rails.error).to receive(:report)
          subject
        end
      end
    end
  end

  describe '#unsubscribe_user' do
    subject { klaviyo_integration.unsubscribe_user(email) }

    let(:klaviyo_integration) do
      create(
        :klaviyo_integration,
        klaviyo_public_api_key: 'RZUvUQ',
        klaviyo_private_api_key: 'pk_8d2bcc4570678967f4d3756fed304430eb',
        default_newsletter_list_id: 'XLUG56'
      )
    end
    let(:email) { 'example@email.com' }

    context 'when email is valid' do
      it 'unsubscribes user' do
        VCR.use_cassette('klaviyo/unsubscribing_user/success') do
          expect(subject.success?).to be true
        end
      end
    end

    context 'when email has wrong format' do
      let(:email) { 'wrong-email' }

      it 'returns failure' do
        VCR.use_cassette('klaviyo/unsubscribing_user/failure') do
          expect(subject.success?).to be false
        end
      end

      it 'sends error to Sentry' do
        VCR.use_cassette('klaviyo/unsubscribing_user/failure') do
          expect(Rails.error).to receive(:report)
          subject
        end
      end
    end
  end

  describe '#create_back_in_stock_subscription', :vcr do
    subject { klaviyo_integration.create_back_in_stock_subscription(email: email, variant_id: variant_id) }

    let(:klaviyo_integration) do
      create(
        :klaviyo_integration
      )
    end

    let(:email) { 'user@gmail.com' }

    context 'when variant id is valid' do
      let(:variant_id) { 'f91550db-8682-404f-81f3-fc48f98de2d0' }

      it 'creates back in stock subscription' do
        expect(subject).to be_success
      end
    end

    context 'when variant id is invalid' do
      let(:variant_id) { 'abcdef-123456' }

      it 'responds with an error' do
        expect(subject).to be_failure
        expect(JSON.parse(subject.value)).to eq(
          { 'errors' => [{ 'code' => 'variant_not_found', 'detail' => 'The variant in your relationship payload does not exist',
                           'id' => 'd232453f-7418-46f7-b580-1630a30ea16d', 'links' => {}, 'meta' => {}, 'source' => { 'pointer' => '/data/relationships/variant/data/id' }, 'status' => 404, 'title' => 'The variant in your relationship payload does not exist' }] }
        )
      end
    end
  end

  describe '#create_event' do
    subject { klaviyo_integration.create_event(event: 'Order Completed', resource: order, email: order.email) }

    let!(:order) { create(:order_with_line_items, store: store) }
    let!(:klaviyo_integration) do
      create(
        :klaviyo_integration,
        klaviyo_public_api_key: 'RZUvUQ',
        klaviyo_private_api_key: 'pk_8d2bcc4570678967f4d3756fed304430eb',
        default_newsletter_list_id: 'XLUG56'
      )
    end

    it 'returns success' do
      VCR.use_cassette('klaviyo/create_event/order_completed/success') do
        expect(subject.success?).to be true
      end
    end

    it 'returns failure' do
      klaviyo_integration.klaviyo_private_api_key = 'invalid_key'
      klaviyo_integration.save
      VCR.use_cassette('klaviyo/create_event/order_completed/failure') do
        expect(subject.success?).to be false
      end
    end

    context 'for a quest user', :vcr do
      subject { klaviyo_integration.create_event(event: 'Product Viewed', resource: product, email: nil, guest_id: 'guest-user-id-abcd1234') }

      let!(:klaviyo_integration) do
        create(
          :klaviyo_integration
        )
      end

      let(:product) { create(:product_in_stock, stores: [store]) }

      it 'tracks the event for a guest user' do
        expect(subject).to be_success
      end
    end
  end

  describe '#can_connect?' do
    subject { klaviyo_integration.can_connect? }

    let(:klaviyo_integration) do
      create(
        :klaviyo_integration,
        klaviyo_public_api_key: 'RZUvUQ',
        klaviyo_private_api_key: klaviyo_private_api_key,
        default_newsletter_list_id: default_newsletter_list_id
      )
    end

    context 'when credentials are valid' do
      let(:klaviyo_private_api_key) { 'pk_8d2bcc4570678967f4d3756fed304430eb' }
      let(:default_newsletter_list_id) { 'XLUG56' }

      it 'returns true' do
        VCR.use_cassette('klaviyo/can_connect/true/success') do
          expect(subject).to be true
        end
      end
    end

    context 'when private api key is invalid' do
      let(:klaviyo_private_api_key) { 'invalid' }
      let(:default_newsletter_list_id) { 'XLUG56' }

      it 'adds an error message' do
        VCR.use_cassette('klaviyo/can_connect/false/invalid_private_api_key') do
          expect(subject).to be(false)
          expect(klaviyo_integration.connection_error_message).to eq('Missing or invalid private key.')
        end
      end
    end

    context 'when default newsletter list id is invalid' do
      let(:klaviyo_private_api_key) { 'pk_8d2bcc4570678967f4d3756fed304430eb' }
      let(:default_newsletter_list_id) { 'invalid' }

      it 'adds an error message' do
        VCR.use_cassette('klaviyo/can_connect/false/invalid_default_newsletter_list_id') do
          expect(subject).to be(false)
          expect(klaviyo_integration.connection_error_message).to eq("A list with id #{default_newsletter_list_id} does not exist.")
        end
      end
    end
  end
end
