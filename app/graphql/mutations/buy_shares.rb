# typed: false
# frozen_string_literal: true

module Mutations
  class BuyShares < BaseMutation
    description "Buy shares at the current price. Only the active player may trade, after both rolls. Shares trade in lots of 500."

    argument :game_id, ID, required: true
    argument :game_stock_id, ID, required: true
    argument :quantity, Integer, required: true, description: "Number of shares; a positive multiple of 500"

    field :transaction, Types::GameTransactionType, null: true
    field :player, Types::PlayerType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:, game_stock_id:, quantity:)
      game = find_game!(game_id)
      player = find_player!(game)
      transaction = TradingService.new(game: game, player: player).buy!(game_stock_id: game_stock_id, quantity: quantity)
      GameEvents.leaderboard_updated(game, transaction: transaction)

      { transaction: transaction, player: player.reload, errors: [] }
    rescue GameRuleError => e
      { transaction: nil, player: nil, errors: [ e.message ] }
    end
  end
end
