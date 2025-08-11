require 'spec_helper'

RSpec.describe Spree.user_class, type: :model do
  include ActiveJob::TestHelper

  describe 'Klaviyo' do
 describe 'Klaviyo' do
   describe '#subscribe_to_klaviyo' do
     let(:user) { build(:user) }
     let!(:klaviyo_integration) { create(:klaviyo_integration) }
 
     before do
       ActiveJob::Base.queue_adapter = :test
       clear_enqueued_jobs
     end
 
     after { clear_enqueued_jobs }
 
     it 'enqueues a SubscribeJob' do
      it 'enqueues a SubscribeJob' do
        expect {
          user.send(:subscribe_to_klaviyo)
        }.to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
      end

      context 'when klaviyo integration is not active' do
        before do
          klaviyo_integration.update(active: false)
        end

        it 'does not enqueue a SubscribeJob' do
          expect {
            user.send(:subscribe_to_klaviyo)
          }.not_to have_enqueued_job(SpreeKlaviyo::SubscribeJob)
        end
      end
    end
  end
end
