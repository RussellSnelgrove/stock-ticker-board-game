# frozen_string_literal: true

module Mutations
  class BuyShares < BaseMutation
    argument :game_id, ID, required: true
    argument :game_stock_id, ID, required: true
    argument :lots, Integer, required: true

    field :player, Types::PlayerType, null: true
    field :errors, [String], null: false

    def resolve(game_id:, game_stock_id:, lots:)
      user = context[:current_user]
      return { player: nil, errors: ["You must be logged in"] } unless user

      game = Game.find_by(id: game_id)
      return { player: nil, errors: ["Game not found"] } unless game
      return { player: nil, errors: ["Game is not in progress"] } unless game.in_progress?

      player = game.players.find_by(user: user)
      return { player: nil, errors: ["You are not in this game"] } unless player

      active = game.active_player
      return { player: nil, errors: ["It is not your turn"] } unless active&.id == player.id

      rolls_this_turn = game.dice_rolls.where(player: player, turn_number: game.current_turn).count
      return { player: nil, errors: ["You must complete both rolls before trading"] } unless rolls_this_turn >= Mutations::RollDice::ROLLS_PER_TURN

      game_stock = game.game_stocks.find_by(id: game_stock_id)
      return { player: nil, errors: ["Stock not found in this game"] } unless game_stock

      result = TradingService.new(player: player, game_stock: game_stock, game: game).buy(lots: lots)

      if result[:success]
        { player: player.reload, errors: [] }
      else
        { player: nil, errors: [result[:error]] }
      end
    end
  end
end
