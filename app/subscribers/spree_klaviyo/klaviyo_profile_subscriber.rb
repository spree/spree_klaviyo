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

      guest_id = event.payload.dig('visitor_id')

      if guest_id.present?
        SpreeKlaviyo::MergeVisitorProfileJob.perform_later(integration.id, user.id, guest_id)
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
      param =
        if event.name == 'address.created' || event.name == 'address.updated'
          event.payload['user_id']
        else
          event.payload['id']
        end
      return unless param

      Spree.user_class.find_by_param(param)
    end

    def find_integration(event)
      store = Spree::Store.find_by(id: event.store_id) || Spree::Store.default
      store.integrations.active.find_by(type: 'Spree::Integrations::Klaviyo')
    end
  end
end
