# typed: strict
# frozen_string_literal: true

class GameClockExpiryJob < ApplicationJob
  extend T::Sig

  sig { params(game_id: Integer).void }
  def perform(game_id)
    game = Game.find_by(id: game_id)
    return unless game&.in_progress?

    compute_net_worths(game)
    game.complete!
  end

  private

  sig { params(game: Game).void }
  def compute_net_worths(game)
    price_by_game_stock_id = game.game_stocks.index_by(&:id).transform_values(&:current_price)

    game.players.each do |player|
      holdings = derive_holdings(player, price_by_game_stock_id.keys)
      portfolio_value = holdings.sum { |game_stock_id, qty| qty * price_by_game_stock_id.fetch(game_stock_id, 0) }
      player.update_column(:net_worth, player.cash + portfolio_value)
    end
  end

  # Returns a Hash of { game_stock_id => quantity } by replaying transactions in order.
  # Handles splits (double quantity) and worthless resets (zero quantity).
  sig { params(player: Player, game_stock_ids: T::Array[Integer]).returns(T::Hash[Integer, Integer]) }
  def derive_holdings(player, game_stock_ids)
    holdings = game_stock_ids.index_with(0)

    player.game_transactions
      .where(game_stock_id: game_stock_ids)
      .order(:id)
      .each do |txn|
        id = txn.game_stock_id
        case txn.transaction_type
        when "buy"           then holdings[id] += txn.quantity
        when "sell"          then holdings[id] -= txn.quantity
        when "stock_split"   then holdings[id] *= 2
        when "worthless_reset" then holdings[id] = 0
        end
      end

    holdings
  end
end
