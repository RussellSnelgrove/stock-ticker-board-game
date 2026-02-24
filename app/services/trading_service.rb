# frozen_string_literal: true

class TradingService
  LOT_SIZE = 500

  def initialize(player:, game_stock:, game:)
    @player = player
    @game_stock = game_stock
    @game = game
  end

  def buy(lots:)
    shares = lots * LOT_SIZE
    cost = (shares * @game_stock.current_price) / 100

    return { success: false, error: "Cannot buy 0 lots" } if lots <= 0
    return { success: false, error: "Insufficient cash (need $#{cost}, have $#{@player.cash})" } if cost > @player.cash

    ActiveRecord::Base.transaction do
      @player.update!(cash: @player.cash - cost)

      holding = @player.holdings.find_or_initialize_by(game_stock: @game_stock)
      holding.quantity = (holding.quantity || 0) + shares
      holding.save!

      GameTransaction.create!(
        player: @player,
        game_stock: @game_stock,
        transaction_type: "buy",
        quantity: shares,
        price_at_time: @game_stock.current_price,
        total_amount: cost,
        turn_number: @game.current_turn
      )
    end

    { success: true, error: nil }
  end

  def sell(lots:)
    shares = lots * LOT_SIZE
    holding = @player.holdings.find_by(game_stock: @game_stock)
    owned = holding&.quantity || 0

    return { success: false, error: "Cannot sell 0 lots" } if lots <= 0
    return { success: false, error: "Insufficient shares (need #{shares}, have #{owned})" } if shares > owned

    proceeds = (shares * @game_stock.current_price) / 100

    ActiveRecord::Base.transaction do
      @player.update!(cash: @player.cash + proceeds)
      holding.update!(quantity: owned - shares)

      GameTransaction.create!(
        player: @player,
        game_stock: @game_stock,
        transaction_type: "sell",
        quantity: shares,
        price_at_time: @game_stock.current_price,
        total_amount: proceeds,
        turn_number: @game.current_turn
      )
    end

    { success: true, error: nil }
  end
end
