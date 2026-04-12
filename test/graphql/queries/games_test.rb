# typed: true
# frozen_string_literal: true

require "test_helper"

class GamesQueryTest < ActiveSupport::TestCase
  QUERY = <<~GQL
    query {
      games {
        id
        name
        status
        inviteCode
      }
    }
  GQL

  test "returns waiting and in_progress games" do
    result = StockTickerSchema.execute(QUERY, context: { current_user: users(:one) })
    games = result.to_h.dig("data", "games")

    names = games.map { |g| g["name"] }
    assert_includes names, games(:waiting_game).name
    assert_includes names, games(:active_game).name
  end

  test "excludes completed games" do
    result = StockTickerSchema.execute(QUERY, context: { current_user: users(:one) })
    games = result.to_h.dig("data", "games")

    names = games.map { |g| g["name"] }
    assert_not_includes names, games(:completed_game).name
  end

  test "returns expected fields" do
    result = StockTickerSchema.execute(QUERY, context: { current_user: users(:one) })
    game = result.to_h.dig("data", "games").first

    assert game.key?("id")
    assert game.key?("name")
    assert game.key?("status")
    assert game.key?("inviteCode")
  end
end
