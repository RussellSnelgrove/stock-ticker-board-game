# typed: false
# frozen_string_literal: true

class GraphqlChannel < ApplicationCable::Channel
  extend T::Sig
  sig { void }
  def subscribed
    @subscription_ids = []
  end

  # ActionCable passes `data` only when method(:execute).arity == 1. sorbet-runtime's
  # wrapper reports arity -1, so the signature must not wrap the method at runtime.
  T::Sig::WithoutRuntime.sig { params(data: T::Hash[String, T.untyped]).void }
  def execute(data)
    query = data["query"]
    variables = ensure_hash(data["variables"])
    operation_name = data["operationName"]
    context = {
      current_user: current_user,
      channel: self
    }

    result = StockTickerSchema.execute(
      query,
      context: context,
      variables: variables,
      operation_name: operation_name
    )

    payload = { result: result.to_h, more: result.subscription? }

    if result.context[:subscription_id]
      @subscription_ids << result.context[:subscription_id]
    end

    transmit(payload)
  end

  sig { void }
  def unsubscribed
    @subscription_ids.each do |sid|
      StockTickerSchema.subscriptions.delete_subscription(sid)
    end
  end

  private

  sig { params(value: T.untyped).returns(T::Hash[T.untyped, T.untyped]) }
  def ensure_hash(value)
    case value
    when String
      value.present? ? JSON.parse(value) : {}
    when Hash
      value
    else
      {}
    end
  end
end
