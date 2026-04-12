# typed: true
# frozen_string_literal: true

require "test_helper"

class GameClockExpiryJobTest < ActiveSupport::TestCase
  test "completes an in_progress game" do
    game = games(:active_game)
    GameClockExpiryJob.new.perform(game.id)
    assert_equal "completed", game.reload.status
  end

  test "triggers game_ended subscription" do
    game = games(:active_game)
    triggered = []
    StockTickerSchema.subscriptions.stub(:trigger, ->(event, args, obj) { triggered << { event: event, game: obj } }) do
      GameClockExpiryJob.new.perform(game.id)
    end
    assert_equal 1, triggered.length
    entry = triggered.fetch(0)
    assert_equal "gameEnded", entry[:event]
    assert_equal game.id, entry[:game].id
  end

  test "does not trigger game_ended for a non-in_progress game" do
    game = games(:waiting_game)
    triggered = []
    StockTickerSchema.subscriptions.stub(:trigger, ->(event, args, obj) { triggered << event }) do
      GameClockExpiryJob.new.perform(game.id)
    end
    assert_empty triggered
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

  test "assigns final_rank to all players" do
    game = games(:active_game)
    GameClockExpiryJob.new.perform(game.id)

    game.players.each do |player|
      assert_not_nil player.reload.final_rank
    end
  end

  test "higher net worth gets a lower rank number" do
    game = games(:active_game)
    GameClockExpiryJob.new.perform(game.id)

    # player_one net_worth=490_000, player_two net_worth=380_000
    p1 = players(:player_one).reload
    p2 = players(:player_two).reload
    assert p1.final_rank < p2.final_rank
  end

  test "tied players share the same rank" do
    game = games(:active_game)
    # Equalise both players' net worth: no transactions, same cash
    players(:player_one).update_columns(cash: 400_000)
    players(:player_two).update_columns(cash: 400_000)
    # Remove existing transactions so portfolio value is 0 for both
    game.players.each { |p| p.game_transactions.delete_all }

    GameClockExpiryJob.new.perform(game.id)

    p1 = players(:player_one).reload
    p2 = players(:player_two).reload
    assert_equal p1.final_rank, p2.final_rank
  end

  test "earlier turn_position wins the tie but both share the rank number" do
    game = games(:active_game)
    players(:player_one).update_columns(cash: 400_000)
    players(:player_two).update_columns(cash: 400_000)
    game.players.each { |p| p.game_transactions.delete_all }

    GameClockExpiryJob.new.perform(game.id)

    # Both ranked 1 — turn_position 0 beats turn_position 1 within the tie,
    # but neither is demoted; they share rank 1.
    assert_equal 1, players(:player_one).reload.final_rank
    assert_equal 1, players(:player_two).reload.final_rank
  end

  test "player after a tie group gets the correct rank" do
    game = games(:active_game)
    # player_one and player_two tie; dropped_player has less cash
    players(:player_one).update_columns(cash: 400_000)
    players(:player_two).update_columns(cash: 400_000)
    players(:dropped_player).update_columns(cash: 100_000)
    game.players.each { |p| p.game_transactions.delete_all }

    GameClockExpiryJob.new.perform(game.id)

    # Two players tied at rank 1 → third player is rank 3 (not rank 2)
    assert_equal 1, players(:player_one).reload.final_rank
    assert_equal 1, players(:player_two).reload.final_rank
    assert_equal 3, players(:dropped_player).reload.final_rank
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
