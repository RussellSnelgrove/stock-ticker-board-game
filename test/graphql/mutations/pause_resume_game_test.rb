# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::PauseResumeGameTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  PAUSE = <<~GQL
    mutation($gameId: ID!) { pauseGame(input: { gameId: $gameId }) { game { status remainingTime } errors } }
  GQL
  RESUME = <<~GQL
    mutation($gameId: ID!) { resumeGame(input: { gameId: $gameId }) { game { status endsAt } errors } }
  GQL

  def run_mutation(query, key, game, user)
    StockTickerSchema.execute(query, variables: { gameId: game.id }, context: { current_user: user }).to_h.dig("data", key)
  end

  test "a solo player can pause and resume" do
    game = games(:solo_game)

    paused = run_mutation(PAUSE, "pauseGame", game, users(:four))
    assert_empty paused["errors"]
    assert_equal "PAUSED", paused.dig("game", "status")
    assert_operator paused.dig("game", "remainingTime"), :>, 0

    assert_enqueued_with(job: GameClockExpiryJob) do
      resumed = run_mutation(RESUME, "resumeGame", game, users(:four))
      assert_empty resumed["errors"]
      assert_equal "IN_PROGRESS", resumed.dig("game", "status")
    end
  end

  test "a multiplayer game cannot be paused" do
    data = run_mutation(PAUSE, "pauseGame", games(:active_game), users(:one))
    assert_equal [ "Only solo games can be paused" ], data["errors"]
  end

  test "only a player in the game can pause it" do
    data = run_mutation(PAUSE, "pauseGame", games(:solo_game), users(:one))
    assert_equal [ "You are not in this game" ], data["errors"]
  end

  test "rejoining a paused solo game restores the player but leaves the clock stopped" do
    game = games(:solo_game)
    game.pause!
    players(:solo_player).update!(status: :dropped)

    result = StockTickerSchema.execute(
      "mutation { joinGame(input: { inviteCode: \"SOLO01\" }) { game { status } errors } }",
      context: { current_user: users(:four) }
    ).to_h.dig("data", "joinGame")

    assert_empty result["errors"]
    assert_equal "PAUSED", result.dig("game", "status")
    assert players(:solo_player).reload.active?
  end

  test "another user cannot join a paused solo game" do
    games(:solo_game).pause!
    result = StockTickerSchema.execute(
      "mutation { joinGame(input: { inviteCode: \"SOLO01\" }) { errors } }",
      context: { current_user: users(:one) }
    ).to_h.dig("data", "joinGame")
    assert_equal [ "This solo game is paused" ], result["errors"]
  end
end
