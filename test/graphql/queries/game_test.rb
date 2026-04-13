# typed: true
# frozen_string_literal: true

require "test_helper"

class GameQueryTest < ActiveSupport::TestCase
  QUERY_BY_ID = <<~GQL
    query($id: ID!) {
      game(id: $id) {
        id
        name
        status
        endsAt
        remainingTime
        rollsRemainingThisTurn
      }
    }
  GQL

  QUERY_BY_INVITE_CODE = <<~GQL
    query($inviteCode: String!) {
      game(inviteCode: $inviteCode) {
        id
        name
        inviteCode
      }
    }
  GQL

  QUERY_NO_ARGS = <<~GQL
    query {
      game {
        id
      }
    }
  GQL

  test "fetches game by id" do
    game = games(:active_game)
    result = StockTickerSchema.execute(QUERY_BY_ID, variables: { id: game.id }, context: { current_user: users(:one) })

    data = result.to_h.dig("data", "game")
    assert_equal game.id.to_s, data["id"]
    assert_equal game.name, data["name"]
    assert_equal "IN_PROGRESS", data["status"]
    assert_not_nil data["endsAt"]
    assert_not_nil data["rollsRemainingThisTurn"]
  end

  test "fetches game by invite code" do
    game = games(:waiting_game)
    result = StockTickerSchema.execute(QUERY_BY_INVITE_CODE, variables: { inviteCode: game.invite_code }, context: { current_user: users(:one) })

    data = result.to_h.dig("data", "game")
    assert_equal game.id.to_s, data["id"]
    assert_equal game.invite_code, data["inviteCode"]
  end

  test "returns null for unknown id" do
    result = StockTickerSchema.execute(QUERY_BY_ID, variables: { id: "0" }, context: { current_user: users(:one) })

    assert_nil result.to_h.dig("data", "game")
  end

  test "returns error when no arguments provided" do
    result = StockTickerSchema.execute(QUERY_NO_ARGS, context: { current_user: users(:one) })

    assert_not_empty result.to_h["errors"]
  end

  test "returns remaining_time for paused game" do
    game = games(:active_game)
    game.pause!
    result = StockTickerSchema.execute(QUERY_BY_ID, variables: { id: game.id }, context: { current_user: users(:one) })

    data = result.to_h.dig("data", "game")
    assert_not_nil data["remainingTime"]
    assert data["remainingTime"] > 0
  end
end
