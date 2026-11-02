# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::TradeSharesTest < ActiveSupport::TestCase
  BUY = <<~GQL
    mutation($gameId: ID!, $gameStockId: ID!, $quantity: Int!) {
      buyShares(input: { gameId: $gameId, gameStockId: $gameStockId, quantity: $quantity }) {
        transaction { transactionType quantity priceAtTime totalAmount }
        player { cash holdings { quantity gameStock { id } } }
        errors
      }
    }
  GQL

  SELL = <<~GQL
    mutation($gameId: ID!, $gameStockId: ID!, $quantity: Int!) {
      sellShares(input: { gameId: $gameId, gameStockId: $gameStockId, quantity: $quantity }) {
        transaction { transactionType quantity totalAmount }
        player { cash }
        errors
      }
    }
  GQL

  setup { games(:active_game).update!(rolls_remaining_this_turn: 0) }

  def run_mutation(query, key, stock, quantity, user: users(:two))
    StockTickerSchema.execute(
      query,
      variables: { gameId: games(:active_game).id, gameStockId: stock.id, quantity: quantity },
      context: { current_user: user }
    ).to_h.dig("data", key)
  end

  test "buyShares buys at the current price" do
    data = run_mutation(BUY, "buyShares", game_stocks(:industrial_in_game_one), 500)

    assert_empty data["errors"]
    assert_equal({ "transactionType" => "BUY", "quantity" => 500, "priceAtTime" => 120, "totalAmount" => 60_000 }, data["transaction"])
    assert_equal 320_000, data.dig("player", "cash")
  end

  test "buyShares returns a user error when cash is short" do
    data = run_mutation(BUY, "buyShares", game_stocks(:industrial_in_game_one), 50_000)
    assert_nil data["transaction"]
    assert_equal [ "Not enough cash for that purchase" ], data["errors"]
  end

  test "sellShares sells at the current price" do
    data = run_mutation(SELL, "sellShares", game_stocks(:bonds_in_game_one), 1000)

    assert_empty data["errors"]
    assert_equal 80_000, data.dig("transaction", "totalAmount")
    assert_equal 460_000, data.dig("player", "cash")
  end

  test "sellShares returns a user error when shares are short" do
    data = run_mutation(SELL, "sellShares", game_stocks(:bonds_in_game_one), 5000)
    assert_equal [ "You do not own that many shares" ], data["errors"]
  end

  test "players who are not active cannot trade" do
    data = run_mutation(BUY, "buyShares", game_stocks(:industrial_in_game_one), 500, user: users(:one))
    assert_equal [ "It is not your turn" ], data["errors"]
  end
end
