# typed: true
# frozen_string_literal: true

require "test_helper"

class GameClockExpiryJobTest < ActiveSupport::TestCase
  setup do
    @game = games(:active_game)
    @game.update_columns(ends_at: 1.second.ago)
  end

  test "completes an in_progress game whose clock has run out" do
    GameClockExpiryJob.new.perform(@game.id)
    assert_equal "completed", @game.reload.status
  end

  test "ignores a stale job when the clock was extended by pause and resume" do
    @game.update_columns(ends_at: 10.minutes.from_now)
    GameClockExpiryJob.new.perform(@game.id)
    assert_equal "in_progress", @game.reload.status
  end

  test "is a no-op for a game that is not in_progress" do
    game = games(:waiting_game)
    GameClockExpiryJob.new.perform(game.id)
    assert_equal "waiting", game.reload.status
  end

  test "is a no-op for an unknown game id" do
    assert_nothing_raised { GameClockExpiryJob.new.perform(0) }
  end

  test "sets net_worth to cash plus holdings at current prices" do
    GameClockExpiryJob.new.perform(@game.id)

    # player_one: 500_000 cash + 500 grain at 100
    assert_equal 550_000, players(:player_one).reload.net_worth
    # player_two: 380_000 cash + 1000 bonds at 80
    assert_equal 460_000, players(:player_two).reload.net_worth
    # dropped_player: cash only
    assert_equal 120_000, players(:dropped_player).reload.net_worth
  end

  test "ranks players by net worth" do
    GameClockExpiryJob.new.perform(@game.id)

    assert_equal 1, players(:player_one).reload.final_rank
    assert_equal 2, players(:player_two).reload.final_rank
    assert_equal 3, players(:dropped_player).reload.final_rank
  end

  test "tied players share a rank and the next player skips a rank" do
    Holding.delete_all
    players(:player_one).update_columns(cash: 400_000)
    players(:player_two).update_columns(cash: 400_000)
    players(:dropped_player).update_columns(cash: 100_000)

    GameClockExpiryJob.new.perform(@game.id)

    assert_equal 1, players(:player_one).reload.final_rank
    assert_equal 1, players(:player_two).reload.final_rank
    assert_equal 3, players(:dropped_player).reload.final_rank
  end
end
