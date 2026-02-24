# frozen_string_literal: true

module Mutations
  class EndTurn < BaseMutation
    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [String], null: false

    def resolve(game_id:)
      user = context[:current_user]
      return { game: nil, errors: ["You must be logged in"] } unless user

      game = Game.find_by(id: game_id)
      return { game: nil, errors: ["Game not found"] } unless game
      return { game: nil, errors: ["Game is not in progress"] } unless game.in_progress?

      player = game.players.find_by(user: user)
      return { game: nil, errors: ["You are not in this game"] } unless player

      active = game.active_player
      return { game: nil, errors: ["It is not your turn"] } unless active&.id == player.id

      rolls_this_turn = game.dice_rolls.where(player: player, turn_number: game.current_turn).count
      return { game: nil, errors: ["You must roll #{Mutations::RollDice::ROLLS_PER_TURN} times before ending your turn"] } unless rolls_this_turn >= Mutations::RollDice::ROLLS_PER_TURN

      advance_to_next_player(game)

      game.reload
      StockTickerSchema.subscriptions.trigger(
        :turn_changed,
        { game_id: game.id },
        { game: game, active_player: game.active_player }
      )

      { game: game, errors: [] }
    end

    private

    def advance_to_next_player(game)
      active_players = game.players.active.by_turn_order.to_a
      return if active_players.empty?

      current_index = active_players.index { |p| p.turn_position == game.active_player&.turn_position }
      next_index = ((current_index || 0) + 1) % active_players.size

      game.update!(current_turn: game.current_turn + 1)
    end
  end
end
