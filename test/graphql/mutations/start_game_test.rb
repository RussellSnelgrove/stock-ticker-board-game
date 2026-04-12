# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::StartGameTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  MUTATION = <<~GQL
    mutation StartGame($gameId: ID!) {
      startGame(input: { gameId: $gameId }) {
        game {
          id
          status
          startsAt
          endsAt
        }
        errors
      }
    }
  GQL

  test "host can start a waiting game" do
    game = games(:waiting_game)

    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: game.id },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "startGame")
    assert_empty data["errors"]

    assert_equal "IN_PROGRESS", data.dig("game", "status")
    assert_not_nil data.dig("game", "startsAt")
    assert_not_nil data.dig("game", "endsAt")
  end

  test "non-host cannot start the game" do
    game = games(:waiting_game)

    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: game.id },
      context: { current_user: users(:two) }
    )

    data = result.to_h.dig("data", "startGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "Only the host"
  end

  test "cannot start a game that is already in progress" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: games(:active_game).id },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "startGame")
    assert_nil data["game"]
    assert data["errors"].any?
  end

  test "returns an error when not logged in" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: games(:waiting_game).id },
      context: { current_user: nil }
    )

    data = result.to_h.dig("data", "startGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "logged in"
  end

  test "returns an error for a non-existent game" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: 0 },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "startGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "not found"
  end

  test "cannot start a game with no active players" do
    game = games(:waiting_game)
    game.players.delete_all

    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: game.id },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "startGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "no players"
  end

  test "schedules GameClockExpiryJob" do
    game = games(:waiting_game)

    assert_enqueued_with(job: GameClockExpiryJob) do
      StockTickerSchema.execute(
        MUTATION,
        variables: { gameId: game.id },
        context: { current_user: users(:one) }
      )
    end
  end
end
