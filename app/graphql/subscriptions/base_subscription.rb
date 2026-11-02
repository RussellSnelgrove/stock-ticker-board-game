# typed: false
# frozen_string_literal: true

module Subscriptions
  # Every game event is scoped to one game. Subscribing sends no initial payload.
  class BaseSubscription < GraphQL::Schema::Subscription
    argument :game_id, ID, required: true

    def subscribe(game_id:)
      raise GraphQL::ExecutionError, "You must be logged in" unless context[:current_user]
      raise GraphQL::ExecutionError, "Game not found" unless Game.exists?(id: game_id)

      :no_response
    end
  end
end
