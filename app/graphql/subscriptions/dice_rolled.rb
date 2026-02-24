# frozen_string_literal: true

module Subscriptions
  class DiceRolled < GraphQL::Schema::Subscription
    argument :game_id, ID, required: true

    field :dice_roll, Types::DiceRollType, null: false
    field :events, [Types::GameEventType], null: false

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
