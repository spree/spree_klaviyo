module SpreeKlaviyo
  class ReimbursementSubscriber < Spree::Subscriber
    subscribes_to 'reimbursement.reimbursed'

    on 'reimbursement.reimbursed', :handle_reimbursement_reimbursed

    private

    def handle_reimbursement_reimbursed(event)
      reimbursement_id = event.payload['id']
      return unless reimbursement_id

      reimbursement = Spree::Reimbursement.find_by_param(reimbursement_id)
      return unless reimbursement

      order = reimbursement.order
      integration = Spree::Integrations::Klaviyo.find_by(store_id: order.store_id)
      return if integration.blank?

      SpreeKlaviyo::AnalyticsEventJob.perform_later(
        integration.id, 'Reimbursement Paid', Spree::Reimbursement.name, reimbursement.id, order.email
      )
    end
  end
end
