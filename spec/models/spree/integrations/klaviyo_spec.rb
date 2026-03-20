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
  subject(:klaviyo_integration) { create(:klaviyo_integration) }

  let(:store) { Spree::Store.default }

  let(:usa) { Spree::Country.find_by(iso: 'US') }
  let(:california) { create(:state, name: 'California', country: usa, abbr: 'CA') }

  let(:user_with_bill_address) { create(:user, klaviyo_id: klaviyo_id, first_name: 'John', last_name: 'Doe', email: 'example@email.com', bill_address: bill_address) }
  let(:bill_address) { create(:bill_address, first_name: 'John', last_name: 'Doe', address1: '123 Main St', city: 'Anytown', state: california, zipcode: '12345', phone: '555-555-0199', country: usa) }

  let(:klaviyo_id) { nil }

  describe 'validations' do
    it 'validates presence of klaviyo_public_api_key' do
      klaviyo_integration.preferred_klaviyo_public_api_key = nil
      expect(klaviyo_integration).to be_invalid
    end

    it 'validates presence of klaviyo_private_api_key' do
      klaviyo_integration.preferred_klaviyo_private_api_key = nil
      expect(klaviyo_integration).to be_invalid
    end

    it 'validates presence of default_newsletter_list_id' do
      klaviyo_integration.preferred_default_newsletter_list_id = nil
      expect(klaviyo_integration).to be_invalid
    end
  end

  describe 'api calls' do
    describe '#subscribe_user' do
      subject(:subscribe_user) { klaviyo_integration.subscribe_user(email) }

      let(:email) { 'example@email.com' }

      context 'when email is valid' do
        subject { VCR.use_cassette('klaviyo/subscribe_user/success') { subscribe_user } }

        it { is_expected.to be_success }
      end

      context 'with invalid request (incorrect email format)' do
        subject { VCR.use_cassette('klaviyo/subscribe_user/failure') { subscribe_user } }

        let(:email) { 'wrong-email' }

        it { is_expected.to be_failure }

        it 'reports the error' do
          expect(Rails.error).to receive(:report)
          subject
        end
      end
    end

    describe '#unsubscribe_user' do
      subject(:unsubscribe_user) { klaviyo_integration.unsubscribe_user(email) }

      let(:email) { 'example@email.com' }

      context 'when email is valid' do
        subject { VCR.use_cassette('klaviyo/unsubscribe_user/success') { unsubscribe_user } }

        it { is_expected.to be_success }
      end

      context 'when email has wrong format' do
        subject { VCR.use_cassette('klaviyo/unsubscribe_user/failure') { unsubscribe_user } }

        let(:email) { 'wrong-email' }

        it { is_expected.to be_failure }
        it 'reports the error' do
          expect(Rails.error).to receive(:report)
          subject
        end
      end
    end

    describe '#create_back_in_stock_subscription' do
      subject(:create_back_in_stock_subscription) { klaviyo_integration.create_back_in_stock_subscription(email: email, variant_id: variant_id) }

      let(:email) { 'user@gmail.com' }

      context 'when variant id is valid' do
        subject { VCR.use_cassette('klaviyo/create_back_in_stock_subscription/success') { create_back_in_stock_subscription } }

        let(:variant_id) { 'f91550db-8682-404f-81f3-fc48f98de2d0' }

        it { is_expected.to be_success }
      end

      context 'when variant id is invalid' do
        subject(:response) { VCR.use_cassette('klaviyo/create_back_in_stock_subscription/failure') { create_back_in_stock_subscription } }

        let(:variant_id) { 'abcdef-123456' }

        it { is_expected.to be_failure }

        describe 'response message' do
          subject(:response_value) { JSON.parse(response.value) }

          it 'returns the correct error message' do
            expect(response_value).to eq(
              { 'errors' => [{ 'code' => 'variant_not_found', 'detail' => 'The variant in your relationship payload does not exist',
                              'id' => 'd232453f-7418-46f7-b580-1630a30ea16d', 'links' => {}, 'meta' => {}, 'source' => { 'pointer' => '/data/relationships/variant/data/id' }, 'status' => 404, 'title' => 'The variant in your relationship payload does not exist' }] }
            )
          end
        end
      end
    end

    describe '#create_event' do
      subject(:create_event) { klaviyo_integration.create_event(**params) }

      context 'for a logged user' do
        subject { VCR.use_cassette('klaviyo/create_event/order_completed_for_a_logged_user/success') { create_event } }

        let(:params) do
          {
            event: 'Order Completed',
            resource: order,
            email: order.email
          }
        end

        let(:order) { create(:order, number: 'R360992544', store: store, email: user.email, line_items: [line_item_1, line_item_2], ship_address: ship_address, bill_address: bill_address, user: user) }
        let(:user) { user_with_bill_address }

        let(:product_1) { create(:product_in_stock, name: 'Product 1', price: 19.99, currency: 'USD', sku: 'SKU-1', stores: [store]) }
        let(:product_2) { create(:product_in_stock, name: 'Product 2', price: 21.37, currency: 'USD', sku: 'SKU-2', stores: [store]) }

        let(:line_item_1) { create(:line_item, product: product_1, price: 19.99, currency: 'USD', quantity: 1) }
        let(:line_item_2) { create(:line_item, product: product_2, price: 21.37, currency: 'USD', quantity: 10) }

        let(:ship_address) { create(:ship_address, first_name: 'John', last_name: 'Ferguson', address1: '456 Oak Ave', city: 'Othertown', state: new_york, zipcode: '67890', phone: '555-555-0199', country: usa) }
        let(:new_york) { create(:state, name: 'New York', country: usa, abbr: 'NY') }

        it { is_expected.to be_success }
      end

      context 'for a quest user' do
        subject { VCR.use_cassette('klaviyo/create_event/product_viewed_for_a_quest_user/success') { create_event } }

        let(:params) do
          {
            event: 'Product Viewed',
            resource: product,
            email: nil,
            guest_id: 'guest-user-id-abcd1234'
          }
        end

        let(:product) { create(:product_in_stock, name: 'Product 42352', price: 19.99, currency: 'USD', sku: 'SKU-4', stores: [store]) }

        it { is_expected.to be_success }
      end
    end

    describe '#create_profile' do
      subject(:create_profile) { klaviyo_integration.create_profile(user) }

      let(:user) { create(:user, email: email) }
      let(:email) { 'example@email.com' }

      context 'with valid request' do
        context 'with minimal required data' do
          it 'sends a successful request' do
            VCR.use_cassette('klaviyo/create_profile/success') do
              expect(subject).to be_success
            end
          end

          describe 'response' do
            subject(:response_value) { JSON.parse(create_profile.value) }

            it 'has expected response' do
              VCR.use_cassette('klaviyo/create_profile/success') do
                expect(response_value.dig('data', 'attributes', 'email')).to eq(email)
              end
            end
          end
        end
      end

      context 'with additional data' do
        subject(:create_profile) { klaviyo_integration.create_profile(user, 'guest-user-id-abcd1234') }

        let(:user) { user_with_bill_address }
        let(:email) { user.email }

        it 'sends a successful request' do
          VCR.use_cassette('klaviyo/create_profile/success_with_additional_data') do
            expect(subject).to be_success
          end
        end
      end
    end

    describe '#update_profile' do
      subject(:update_profile) { klaviyo_integration.update_profile(user) }

      let(:user) { user_with_bill_address }
      let(:klaviyo_id) { '01KM0AN5P8BYVMH6HZ4PEBT2CW' }

      context 'with valid request' do
        it 'sends a successful request' do
          VCR.use_cassette('klaviyo/update_profile/success') do
            expect(subject).to be_success
          end
        end
      end

      context 'with invalid request' do
        let(:klaviyo_id) { 'invalid' }

        it 'sends a failed request' do
          VCR.use_cassette('klaviyo/update_profile/failure') do
            expect(subject).to be_failure
          end
        end
      end
    end
  end

  describe '#can_connect?' do
    subject(:can_connect) { klaviyo_integration.can_connect? }

    context 'with valid credentials' do
      subject { VCR.use_cassette('klaviyo/can_connect/success') { can_connect } }

      it { is_expected.to be true }
    end

    context 'when private api key is invalid' do
      let(:klaviyo_integration) { create(:klaviyo_integration, preferred_klaviyo_private_api_key: 'invalid') }

      subject(:request) { VCR.use_cassette('klaviyo/can_connect/invalid_private_api_key') { can_connect } }

      it { is_expected.to be false }

      describe 'response message' do
        subject(:response_value) { klaviyo_integration.connection_error_message }

        let(:expected_message) { 'Missing or invalid private key.' }

        it 'sets the connection error message' do
          request

          expect(response_value).to eq(expected_message)
        end
      end
    end

    context 'when default newsletter list id is invalid' do
      let(:klaviyo_integration) { create(:klaviyo_integration, preferred_default_newsletter_list_id: 'invalid') }

      subject(:request) { VCR.use_cassette('klaviyo/can_connect/invalid_default_newsletter_list_id') { can_connect } }

      it { is_expected.to be false }

      describe 'response message' do
        subject(:response_value) { klaviyo_integration.connection_error_message }

        let(:expected_message) { "A list with id `invalid` does not exist." }

        it 'sets the connection error message' do
          request

          expect(response_value).to eq(expected_message)
        end
      end
    end
  end
end