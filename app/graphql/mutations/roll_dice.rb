# frozen_string_literal: true

module Mutations
  class RollDice < BaseMutation
    ROLLS_PER_TURN = 2

    argument :game_id, ID, required: true

    field :dice_roll, Types::DiceRollType, null: true
    field :events, [Types::GameEventType], null: false
    field :game, Types::GameType, null: true
    field :rolls_remaining, Integer, null: false
    field :errors, [String], null: false

    def resolve(game_id:)
      user = context[:current_user]
      return error_result("You must be logged in") unless user

      game = Game.find_by(id: game_id)
      return error_result("Game not found") unless game
      return error_result("Game is not in progress") unless game.in_progress?

      player = game.players.find_by(user: user)
      return error_result("You are not in this game") unless player

      active = game.active_player
      return error_result("It is not your turn") unless active&.id == player.id

      rolls_this_turn = game.dice_rolls.where(player: player, turn_number: game.current_turn).count
      return error_result("You have already rolled #{ROLLS_PER_TURN} times this turn. Trade or end your turn.") if rolls_this_turn >= ROLLS_PER_TURN

      result = DiceRollingService.new(game: game, player: player).roll!

      remaining = ROLLS_PER_TURN - rolls_this_turn - 1
      game_events = result.events.map { |e| { event_type: e[:type], stock_symbol: e[:stock], message: e[:message] } }

      { dice_roll: result.dice_roll, events: game_events, game: game.reload, rolls_remaining: remaining, errors: [] }
    end

    private

    def error_result(msg)
      { dice_roll: nil, events: [], game: nil, rolls_remaining: 0, errors: [msg] }
    end
  end
end
