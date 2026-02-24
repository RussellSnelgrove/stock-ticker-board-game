# frozen_string_literal: true

class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    @subscription_ids = []
  end

  def execute(data)
    result = StockTickerSchema.execute(
      query: data["query"],
      context: {
        current_user: current_user,
        channel: self
      },
      variables: data["variables"],
      operation_name: data["operationName"]
    )

    payload = { result: result.to_h, more: result.subscription? }

    @subscription_ids << result.context[:subscription_id] if result.context[:subscription_id]

    transmit(payload)
  end

  def unsubscribed
    @subscription_ids.each do |sid|
      StockTickerSchema.subscriptions.delete_subscription(sid)
    end
  end
end
