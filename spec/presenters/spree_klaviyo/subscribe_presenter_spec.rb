require 'spec_helper'

RSpec.describe SpreeKlaviyo::SubscribePresenter do
  subject { described_class.new(email: email, list_id: list_id, type: type, subscribed: subscribed).call }

  let(:email) { 'test@example.com' }
  let(:list_id) { 'list_123' }
  let(:type) { 'profile-subscription-bulk-create-job' }
  let(:subscribed) { true }

  describe '#call' do
    context 'when subscribed is true' do
      let(:subscribed) { true }

      it 'returns the subscription data with SUBSCRIBED consent' do
        expect(subject).to eq(
          data: {
            type: 'profile-subscription-bulk-create-job',
            attributes: {
              profiles: {
                data: [
                  {
                    type: 'profile',
                    attributes: {
                      email: 'test@example.com',
                      subscriptions: {
                        email: {
                          marketing: {
                            consent: 'SUBSCRIBED'
                          }
                        }
                      }
                    }
                  }
                ]
              }
            },
            relationships: {
              list: {
                data: {
                  type: 'list',
                  id: 'list_123'
                }
              }
            }
          }
        )
      end
    end

    context 'when subscribed is false' do
      let(:subscribed) { false }

      it 'returns the subscription data with UNSUBSCRIBED consent' do
        expect(subject).to eq(
          data: {
            type: 'profile-subscription-bulk-create-job',
            attributes: {
              profiles: {
                data: [
                  {
                    type: 'profile',
                    attributes: {
                      email: 'test@example.com',
                      subscriptions: {
                        email: {
                          marketing: {
                            consent: 'UNSUBSCRIBED'
                          }
                        }
                      }
                    }
                  }
                ]
              }
            },
            relationships: {
              list: {
                data: {
                  type: 'list',
                  id: 'list_123'
                }
              }
            }
          }
        )
      end
    end

    context 'with custom type' do
      let(:type) { 'custom-subscription-type' }

      it 'uses the custom type in the data structure' do
        expect(subject[:data][:type]).to eq('custom-subscription-type')
      end
    end

    context 'with different email and list_id' do
      let(:email) { 'user@domain.com' }
      let(:list_id) { 'custom_list_456' }

      it 'uses the provided email and list_id' do
        expect(subject[:data][:attributes][:profiles][:data][0][:attributes][:email]).to eq('user@domain.com')
        expect(subject[:data][:relationships][:list][:data][:id]).to eq('custom_list_456')
      end
    end

    context 'with default parameters' do
      subject { described_class.new(email: email, list_id: list_id).call }

      it 'uses default type and subscribed values' do
        expect(subject[:data][:type]).to eq('profile-subscription-bulk-create-job')
        expect(subject[:data][:attributes][:profiles][:data][0][:attributes][:subscriptions][:email][:marketing][:consent]).to eq('SUBSCRIBED')
      end
    end
  end

  describe 'constants' do
    it 'defines SUBSCRIBED constant' do
      expect(described_class::SUBSCRIBED).to eq('SUBSCRIBED')
    end

    it 'defines UNSUBSCRIBED constant' do
      expect(described_class::UNSUBSCRIBED).to eq('UNSUBSCRIBED')
    end
  end
end
