# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::LeaveGameTest < ActiveSupport::TestCase
  MUTATION = <<~GQL
    mutation LeaveGame($gameId: ID!) {
      leaveGame(input: { gameId: $gameId }) {
        game { id }
        errors
      }
    }
  GQL

  test "active player can leave a game" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: games(:active_game).id },
      context: { current_user: users(:one) }
    )

    assert_empty result.to_h.dig("data", "leaveGame", "errors")
    assert players(:player_one).reload.dropped?
  end

  test "leaving preserves the player record" do
    assert_no_difference "Player.count" do
      StockTickerSchema.execute(
        MUTATION,
        variables: { gameId: games(:active_game).id },
        context: { current_user: users(:one) }
      )
    end
  end

  test "returns an error when already dropped" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: games(:active_game).id },
      context: { current_user: users(:three) }
    )

    data = result.to_h.dig("data", "leaveGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "already left"
  end

  test "returns an error when not in the game" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: games(:waiting_game).id },
      context: { current_user: users(:two) }
    )

    data = result.to_h.dig("data", "leaveGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "not in this game"
  end

  test "returns an error when not logged in" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: games(:active_game).id },
      context: { current_user: nil }
    )

    data = result.to_h.dig("data", "leaveGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "logged in"
  end

  test "returns an error for a non-existent game" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { gameId: 0 },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "leaveGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "not found"
  end
end
