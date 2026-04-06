# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::CreateGameTest < ActiveSupport::TestCase
  MUTATION = <<~GQL
    mutation CreateGame($name: String!, $duration: Int!) {
      createGame(input: { name: $name, duration: $duration }) {
        game {
          id
          name
          status
          inviteCode
          rollsRemainingThisTurn
          gameStocks {
            currentPrice
            stock { name }
          }
        }
        errors
      }
    }
  GQL

  test "creates a game in waiting status with 6 stocks at $1.00" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { name: "Test Game", duration: 30 },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "createGame")
    assert_empty data["errors"]

    game = data["game"]
    assert_equal "Test Game", game["name"]
    assert_equal "WAITING", game["status"]
    assert_equal 2, game["rollsRemainingThisTurn"]
    assert_match(/\A[A-Z0-9]{6}\z/, game["inviteCode"])

    stocks = game["gameStocks"]
    assert_equal 6, stocks.length
    assert stocks.all? { |s| s["currentPrice"] == 100 }
    assert_equal Stock::NAMES, stocks.map { |s| s.dig("stock", "name") }
  end

  test "returns an error for an invalid duration" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { name: "Bad Game", duration: 45 },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "createGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "Duration must be one of"
  end

  test "returns an error when not logged in" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { name: "Ghost Game", duration: 30 },
      context: { current_user: nil }
    )

    data = result.to_h.dig("data", "createGame")
    assert_nil data["game"]
    assert_includes data["errors"].first, "logged in"
  end

  test "returns an error for a blank name" do
    result = StockTickerSchema.execute(
      MUTATION,
      variables: { name: "", duration: 60 },
      context: { current_user: users(:one) }
    )

    data = result.to_h.dig("data", "createGame")
    assert_nil data["game"]
    assert data["errors"].any?
  end

  test "does not create game_stocks on failure" do
    assert_no_difference "GameStock.count" do
      StockTickerSchema.execute(
        MUTATION,
        variables: { name: "", duration: 60 },
        context: { current_user: users(:one) }
      )
    end
  end
end
