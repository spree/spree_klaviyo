module SpreeKlaviyo
  class OrderAttributesPresenter
    def initialize(order:, event_name:)
      @order = order
      @event_name = event_name
    end

    def call
      {
        value: @order.total&.to_f,
        time: time(@order)&.iso8601
      }
    end

    private

    def time(order)
      case @event_name
      when ::Spree::Analytics.events[:order_completed]
        order.completed_at
      when ::Spree::Analytics.events[:order_canceled]
        order.canceled_at
      else
        order.updated_at
      end
    end
  end
end
