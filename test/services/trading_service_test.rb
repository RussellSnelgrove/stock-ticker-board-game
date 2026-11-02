# typed: true
# frozen_string_literal: true

require "test_helper"

class TradingServiceTest < ActiveSupport::TestCase
  setup do
    @game = games(:active_game)
    @game.update!(rolls_remaining_this_turn: 0)
    @player = players(:player_two) # 380_000 cash, 1000 bonds
    @service = TradingService.new(game: @game, player: @player)
    @industrial = game_stocks(:industrial_in_game_one) # $1.20
    @bonds = game_stocks(:bonds_in_game_one) # $0.80
  end

  test "buying deducts cash, adds shares, and logs the trade" do
    transaction = @service.buy!(game_stock_id: @industrial.id, quantity: 1000)

    assert_equal 380_000 - 120_000, @player.reload.cash
    assert_equal 1000, @player.holdings.find_by(game_stock: @industrial).quantity
    assert_equal "buy", transaction.transaction_type
    assert_equal 120, transaction.price_at_time
    assert_equal 120_000, transaction.total_amount
    assert_equal 3, transaction.turn_number
  end

  test "buying adds to an existing holding" do
    @service.buy!(game_stock_id: @bonds.id, quantity: 500)
    assert_equal 1500, @player.holdings.find_by(game_stock: @bonds).quantity
  end

  test "a player can spend exactly all their cash" do
    @player.update!(cash: 60_000)
    @service.buy!(game_stock_id: @industrial.id, quantity: 500)
    assert_equal 0, @player.reload.cash
  end

  test "buying more than the player can afford is rejected" do
    error = assert_raises(GameRuleError) { @service.buy!(game_stock_id: @industrial.id, quantity: 5000) }
    assert_equal "Not enough cash for that purchase", error.message
    assert_equal 380_000, @player.reload.cash
  end

  test "selling adds cash, removes shares, and logs the trade" do
    transaction = @service.sell!(game_stock_id: @bonds.id, quantity: 500)

    assert_equal 380_000 + 40_000, @player.reload.cash
    assert_equal 500, @player.holdings.find_by(game_stock: @bonds).quantity
    assert_equal "sell", transaction.transaction_type
  end

  test "selling every share removes the holding" do
    @service.sell!(game_stock_id: @bonds.id, quantity: 1000)
    assert_nil @player.holdings.find_by(game_stock: @bonds)
  end

  test "selling more shares than owned is rejected" do
    error = assert_raises(GameRuleError) { @service.sell!(game_stock_id: @bonds.id, quantity: 1500) }
    assert_equal "You do not own that many shares", error.message
  end

  test "selling a stock the player does not hold is rejected" do
    assert_raises(GameRuleError) { @service.sell!(game_stock_id: @industrial.id, quantity: 500) }
  end

  test "several trades are allowed in one turn" do
    @service.sell!(game_stock_id: @bonds.id, quantity: 1000)
    @service.buy!(game_stock_id: @industrial.id, quantity: 500)
    assert_equal 380_000 + 80_000 - 60_000, @player.reload.cash
  end

  test "quantities must be whole lots of 500" do
    [ 0, -500, 250, 750 ].each do |quantity|
      error = assert_raises(GameRuleError) { @service.buy!(game_stock_id: @industrial.id, quantity: quantity) }
      assert_equal "Shares trade in lots of 500", error.message
    end
  end

  test "trading before both rolls are done is rejected" do
    @game.update!(rolls_remaining_this_turn: 1)
    error = assert_raises(GameRuleError) { @service.buy!(game_stock_id: @industrial.id, quantity: 500) }
    assert_equal "Finish both rolls before trading", error.message
  end

  test "only the active player may trade" do
    service = TradingService.new(game: @game, player: players(:player_one))
    error = assert_raises(GameRuleError) { service.buy!(game_stock_id: @industrial.id, quantity: 500) }
    assert_equal "It is not your turn", error.message
  end

  test "trading is frozen once the clock runs out" do
    @game.update_columns(ends_at: 1.second.ago)
    assert_raises(GameRuleError) { @service.buy!(game_stock_id: @industrial.id, quantity: 500) }
  end

  test "a stock from another game is rejected" do
    other = Game.create!(name: "Other", host: users(:one), duration: 15)
    other_stock = other.game_stocks.create!(stock: stocks(:grain))
    assert_raises(GameRuleError) { @service.buy!(game_stock_id: other_stock.id, quantity: 500) }
  end
end
