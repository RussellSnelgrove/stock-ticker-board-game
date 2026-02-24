# frozen_string_literal: true

module Subscriptions
  class GameStockPriceUpdated < GraphQL::Schema::Subscription
    argument :game_id, ID, required: true

    field :game_stock, Types::GameStockType, null: false
    field :event_type, String, null: false
    field :message, String, null: false

    def authorized?(game_id:)
      game = Game.find_by(id: game_id)
      return false unless game
      game.players.exists?(user: context[:current_user])
    end

    def update
      object
    end
  end
end
