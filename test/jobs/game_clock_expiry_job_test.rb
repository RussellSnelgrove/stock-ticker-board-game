# typed: true
# frozen_string_literal: true

require "test_helper"

class GameClockExpiryJobTest < ActiveSupport::TestCase
  test "completes an in_progress game" do
    game = games(:active_game)
    GameClockExpiryJob.new.perform(game.id)
    assert_equal "completed", game.reload.status
  end

  test "is a no-op for a game that is not in_progress" do
    game = games(:waiting_game)
    GameClockExpiryJob.new.perform(game.id)
    assert_equal "waiting", game.reload.status
  end

  test "is a no-op for an unknown game id" do
    assert_nothing_raised { GameClockExpiryJob.new.perform(0) }
  end

  test "sets net_worth on all players" do
    game = games(:active_game)
    GameClockExpiryJob.new.perform(game.id)

    game.players.each do |player|
      assert_not_nil player.reload.net_worth
    end
  end

  test "computes net_worth as cash plus portfolio value from transactions" do
    game = games(:active_game)
    GameClockExpiryJob.new.perform(game.id)

    player = players(:player_one).reload

    # player_one: cash=500_000
    # buy_grain: +500 shares of grain (current_price: 100) → +50_000
    # sell_industrial: -500 shares of industrial (current_price: 120) → -60_000
    # net_worth = 500_000 + 50_000 - 60_000 = 490_000
    assert_equal 490_000, player.net_worth
  end

  test "computes net_worth as cash only for player with no transactions" do
    game = games(:active_game)
    GameClockExpiryJob.new.perform(game.id)

    player = players(:player_two).reload
    assert_equal player.cash, player.net_worth
  end

  test "worthless_reset zeroes out holdings for that stock" do
    game = games(:active_game)
    grain_stock = game_stocks(:grain_in_game_one)
    player = players(:player_two)

    # Give player_two 1000 grain then a worthless_reset
    player.game_transactions.create!(
      game_stock: grain_stock,
      transaction_type: :buy,
      quantity: 1000,
      price_at_time: 100,
      total_amount: 100_000,
      turn_number: 5
    )
    player.game_transactions.create!(
      game_stock: grain_stock,
      transaction_type: :worthless_reset,
      quantity: 0,
      price_at_time: 0,
      total_amount: 0,
      turn_number: 6
    )

    GameClockExpiryJob.new.perform(game.id)

    # Holdings wiped — net_worth should just be cash
    assert_equal player.reload.cash, player.reload.net_worth
  end
end
