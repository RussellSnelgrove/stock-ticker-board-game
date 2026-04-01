# typed: strict
# frozen_string_literal: true

class StockTickerSchema < GraphQL::Schema
  query(Types::QueryType)
  mutation(Types::MutationType)
  subscription(Types::SubscriptionType)

  use GraphQL::Subscriptions::ActionCableSubscriptions
  use GraphQL::Dataloader

  T::Sig::WithoutRuntime.sig { params(err: T.untyped, context: T.untyped).void }
  def self.type_error(err, context)
    super
  end

  # graphql-ruby prepends ResolveTypeWithType onto this method, so we use
  # WithoutRuntime to avoid a conflict with sorbet-runtime's wrapper.
  T::Sig::WithoutRuntime.sig { params(abstract_type: T.untyped, obj: T.untyped, ctx: T.untyped).returns(T.untyped) }
  def self.resolve_type(abstract_type, obj, ctx)
    raise(GraphQL::RequiredImplementationMissingError)
  end

  max_query_string_tokens(5000)
  validate_max_errors(100)
end
