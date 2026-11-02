# typed: false
# frozen_string_literal: true

module Mutations
  class EndTurn < BaseMutation
    description "End the active player's turn after both rolls and pass play to the next player."

    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:)
      game = find_game!(game_id)
      player = find_player!(game)

      game.with_lock do
        raise GameRuleError, "The game is not running" unless game.clock_running?
        raise GameRuleError, "It is not your turn" unless game.active_player_id == player.id
        raise GameRuleError, "Finish both rolls before ending your turn" unless game.rolls_remaining_this_turn.zero?

        game.advance_turn!
      end
      GameEvents.turn_changed(game)

      { game: game, errors: [] }
    rescue GameRuleError => e
      { game: nil, errors: [ e.message ] }
    end
  end
end
