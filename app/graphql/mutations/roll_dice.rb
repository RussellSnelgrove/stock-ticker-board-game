# typed: false
# frozen_string_literal: true

module Mutations
  class RollDice < BaseMutation
    description "Roll the three dice for the active player. The market moves after each roll; each turn has two rolls."

    argument :game_id, ID, required: true

    field :roll, Types::RollResultType, null: true
    field :rolls_remaining, Integer, null: true
    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:)
      game = find_game!(game_id)
      result = DiceRollingService.new(game: game, player: find_player!(game)).roll!
      GameEvents.dice_rolled(game, result)

      { roll: result, rolls_remaining: result.rolls_remaining, game: game.reload, errors: [] }
    rescue GameRuleError => e
      { roll: nil, rolls_remaining: nil, game: nil, errors: [ e.message ] }
    end
  end
end
