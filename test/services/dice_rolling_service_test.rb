# typed: true
# frozen_string_literal: true

require "test_helper"

class DiceRollingServiceTest < ActiveSupport::TestCase
  Dice = DiceRollingService::Dice

  setup do
    @game = games(:active_game)
    @player = players(:player_two) # holds the turn in the fixture
    @service = DiceRollingService.new(game: @game, player: @player)
  end

  def roll(stock, direction, amount)
    @service.roll!(Dice.new(stock_name: stock, direction: direction, amount: amount))
  end

  test "an up roll raises the price and uses up one roll" do
    result = roll("Industrial", "up", 10)

    assert_equal "up", result.outcome
    assert_equal 120, result.previous_price
    assert_equal 130, game_stocks(:industrial_in_game_one).reload.current_price
    assert_equal 1, result.rolls_remaining
    assert_equal 1, @game.reload.rolls_remaining_this_turn
  end

  test "a down roll lowers the price" do
    result = roll("Bonds", "down", 20)

    assert_equal "down", result.outcome
    assert_equal 60, game_stocks(:bonds_in_game_one).reload.current_price
  end

  test "each roll is recorded with the turn number" do
    result = roll("Oil", "up", 5)

    dice_roll = result.dice_roll
    assert_equal "Oil", dice_roll.stock_rolled.name
    assert_equal "up", dice_roll.direction
    assert_equal 5, dice_roll.amount
    assert_equal 3, dice_roll.turn_number
    assert_equal @player, dice_roll.player
  end

  test "reaching $2.00 splits the stock: holders' shares double and the price resets to $1.00" do
    holding = Holding.create!(player: players(:player_one), game_stock: game_stocks(:silver_in_game_one), quantity: 1500)

    result = roll("Silver", "up", 20) # 195 + 20 → capped at 200

    assert_equal "split", result.outcome
    assert_equal 100, result.new_price
    assert_equal 3000, holding.reload.quantity
    split = GameTransaction.stock_split.last
    assert_equal 1500, split.quantity
    assert_equal 0, split.total_amount
  end

  test "reaching exactly $2.00 also splits" do
    game_stocks(:silver_in_game_one).update!(current_price: 190)
    assert_equal "split", roll("Silver", "up", 10).outcome
  end

  test "falling to $0.00 makes the stock worthless: holders lose their shares and the price resets to $1.00" do
    holding = Holding.create!(player: players(:player_one), game_stock: game_stocks(:gold_in_game_one), quantity: 2000)
    cash_before = players(:player_one).cash

    result = roll("Gold", "down", 20) # 10 - 20 → floor at 0

    assert_equal "worthless", result.outcome
    assert_equal 100, result.new_price
    assert_not Holding.exists?(holding.id)
    assert_equal cash_before, players(:player_one).reload.cash
    assert_equal 2000, GameTransaction.worthless_reset.last.quantity
  end

  test "falling to exactly $0.00 is worthless" do
    game_stocks(:gold_in_game_one).update!(current_price: 5)
    assert_equal "worthless", roll("Gold", "down", 5).outcome
  end

  test "a dividend at $1.00 or more pays the die's percentage of the price per share" do
    # player_one holds 500 grain at $1.00; a 20% dividend pays $0.20 × 500 = $100
    result = roll("Grain", "dividend", 20)

    assert_equal "dividend", result.outcome
    assert_equal 500_000 + 10_000, players(:player_one).reload.cash
    assert_equal 100, game_stocks(:grain_in_game_one).reload.current_price
    assert_equal 10_000, GameTransaction.dividend.last.total_amount
  end

  test "a dividend below $1.00 pays nothing" do
    # player_two holds 1000 bonds at $0.80
    cash_before = @player.cash
    result = roll("Bonds", "dividend", 10)

    assert_equal "dividend_skipped", result.outcome
    assert_equal cash_before, @player.reload.cash
  end

  test "a dropped player's holdings still take part in splits and dividends" do
    Holding.create!(player: players(:dropped_player), game_stock: game_stocks(:grain_in_game_one), quantity: 500)
    roll("Grain", "dividend", 10)
    assert_equal 120_000 + 5_000, players(:dropped_player).reload.cash
  end

  test "only the active player may roll" do
    service = DiceRollingService.new(game: @game, player: players(:player_one))
    error = assert_raises(GameRuleError) { service.roll! }
    assert_equal "It is not your turn", error.message
  end

  test "a player gets two rolls per turn" do
    roll("Oil", "up", 5)
    roll("Oil", "up", 5)
    error = assert_raises(GameRuleError) { roll("Oil", "up", 5) }
    assert_equal "You have no rolls left this turn", error.message
  end

  test "nobody may roll after the clock runs out" do
    @game.update_columns(ends_at: 1.second.ago)
    assert_raises(GameRuleError) { @service.roll! }
  end

  test "nobody may roll before the game starts" do
    service = DiceRollingService.new(game: games(:waiting_game), player: players(:waiting_game_host))
    assert_raises(GameRuleError) { service.roll! }
  end

  test "throw_dice draws each die from its full set of faces" do
    random = Random.new(42)
    throws = Array.new(600) { DiceRollingService.throw_dice(random) }

    assert_equal Stock::NAMES.sort, throws.map(&:stock_name).uniq.sort
    assert_equal %w[dividend down up], throws.map(&:direction).uniq.sort
    assert_equal [ 5, 10, 20 ], throws.map(&:amount).uniq.sort
  end
end
