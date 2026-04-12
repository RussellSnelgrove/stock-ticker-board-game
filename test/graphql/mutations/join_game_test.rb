# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::JoinGameTest < ActiveSupport::TestCase
  MUTATION = <<~GQL
    mutation JoinGame($inviteCode: String!) {
      joinGame(input: { inviteCode: $inviteCode }) {
        game {
          id
          players {
            id
            status
            turnPosition
            cash
          }
        }
        errors
      }
    }
  GQL

  # New player joining -------------------------------------------------------

  test "new player can join a waiting game" do
    assert_difference "Player.count", 1 do
      result = StockTickerSchema.execute(
        MUTATION,
        variables: { inviteCode: "WAIT01" },
        context: { current_user: users(:one) }
      )
      assert_empty result.to_h.dig("data", "joinGame", "errors")
    end
  end

  test "new player gets $5,000 cash and the next turn_position" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { inviteCode: "WAIT01" },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "joinGame")
    assert_empty data["errors"]

    # waiting_game has no existing players, so this player gets position 0
    new_player = data.dig("game", "players").find { |p| p["turnPosition"] == 0 }
    assert_not_nil new_player
    assert_equal 500_000, new_player["cash"]
    assert_equal "ACTIVE", new_player["status"]
  end

  test "invite code lookup is case-insensitive" do
    assert_difference "Player.count", 1 do
      result = StockTickerSchema.execute(
        MUTATION,
        variables: { inviteCode: "wait01" },
        context: { current_user: users(:one) }
      )
      assert_empty result.to_h.dig("data", "joinGame", "errors")
    end
  end

  test "new mid-game player gets appended turn_position" do
    # active_game already has players at positions 0, 1, 2 (dropped)
    # a brand-new user should get position 3
    new_user = User.create!(display_name: "Dave")

    result = StockTickerSchema.execute(
      MUTATION,
      variables: { inviteCode: "ACT001" },
      context: { current_user: new_user }
    )

    data = result.to_h.dig("data", "joinGame")
    assert_empty data["errors"]

    player = data.dig("game", "players").find { |p| p["turnPosition"] == 3 }
    assert_not_nil player
    assert_equal 500_000, player["cash"]
  end

  # Rejoining (restore dropped state) ----------------------------------------

  test "dropped player can rejoin and is reactivated" do
    assert_no_difference "Player.count" do
      result = StockTickerSchema.execute(
        MUTATION,
        variables: { inviteCode: "ACT001" },
        context: { current_user: users(:three) }
      )
      assert_empty result.to_h.dig("data", "joinGame", "errors")
    end

    assert players(:dropped_player).reload.active?
  end

  test "rejoining preserves the dropped player's existing cash and turn_position" do
    dropped = players(:dropped_player)
    original_cash = dropped.cash
    original_position = dropped.turn_position

    StockTickerSchema.execute(
      MUTATION,
      variables: { inviteCode: "ACT001" },
      context: { current_user: users(:three) }
    )

    dropped.reload
    assert_equal original_cash, dropped.cash
    assert_equal original_position, dropped.turn_position
  end

  test "active player joining again is a no-op" do
    assert_no_difference "Player.count" do
      result = StockTickerSchema.execute(
        MUTATION,
        variables: { inviteCode: "ACT001" },
        context: { current_user: users(:one) }
      )
      assert_empty result.to_h.dig("data", "joinGame", "errors")
    end
  end

  # Error cases --------------------------------------------------------------

  test "returns an error when not logged in" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { inviteCode: "WAIT01" },
      context: { current_user: nil }
    )

    data = result.to_h.dig("data", "joinGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "logged in"
  end

  test "returns an error for an unknown invite code" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { inviteCode: "XXXXXX" },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "joinGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "not found"
  end

  test "returns an error when the game has ended" do
    games(:active_game).update!(status: :completed)

    result = StockTickerSchema.execute(
      MUTATION,
      variables: { inviteCode: "ACT001" },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "joinGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "ended"
  end
end
