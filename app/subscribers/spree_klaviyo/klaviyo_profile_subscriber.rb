module SpreeKlaviyo
  class KlaviyoProfileSubscriber < Spree::Subscriber
    subscribes_to 'user.created', 'user.updated', 'address.created', 'address.updated'

    on 'user.created', :handle_user_created
    on 'user.updated', :handle_profile_upsert
    on 'address.created', :handle_profile_upsert
    on 'address.updated', :handle_profile_upsert

    private

    def handle_user_created(event)
      user = find_user(event)
      return unless user

      integration = find_integration(event)
      return unless integration

      if user.klaviyo_visitor_id.present?
        SpreeKlaviyo::MergeVisitorProfileJob.perform_later(integration.id, user.id, user.klaviyo_visitor_id)
      else
        SpreeKlaviyo::CreateOrUpdateProfileJob.perform_later(integration.id, user.id)
      end
    rescue StandardError => e
      Rails.error.report(e, context: { event_name: 'user.created' }, source: 'spree_klaviyo')
    end

    def handle_profile_upsert(event)
      user = find_user(event)
      return unless user

      integration = find_integration(event)
      return unless integration

      SpreeKlaviyo::CreateOrUpdateProfileJob.perform_later(integration.id, user.id)
    rescue StandardError => e
      Rails.error.report(e, context: { event_name: event.name }, source: 'spree_klaviyo')
    end

    def find_user(event)
      user_id = event.payload['id']
      return unless user_id

      Spree.user_class.find_by_param(user_id)
    end

    def find_integration(event)
      store = Spree::Store.find_by(id: event.store_id) || Spree::Store.default
      store.integrations.active.find_by(type: 'Spree::Integrations::Klaviyo')
    end
  end
end
