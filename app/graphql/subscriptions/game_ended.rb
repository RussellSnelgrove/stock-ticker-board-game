# typed: false
# frozen_string_literal: true

module Subscriptions
  class GameEnded < GraphQL::Schema::Subscription
    description "Fired when the game clock expires. Includes final rankings."

    argument :game_id, ID, required: true

    field :game, Types::GameType, null: false

    def subscribe(game_id:)
      game = Game.find_by(id: game_id)
      return { game: game } if game
      { errors: [ "Game not found" ] }
    end

    def update(game_id:)
      { game: object }
    end
  end
end
