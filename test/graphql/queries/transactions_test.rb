# typed: true
# frozen_string_literal: true

require "test_helper"

class TransactionsQueryTest < ActiveSupport::TestCase
  QUERY = <<~GQL
    query($gameId: ID!, $first: Int, $after: String) {
      transactions(gameId: $gameId, first: $first, after: $after) {
        nodes { transactionType quantity }
        pageInfo { hasNextPage endCursor }
      }
    }
  GQL

  def fetch(**vars)
    StockTickerSchema.execute(QUERY, variables: { gameId: games(:active_game).id, **vars }, context: { current_user: users(:one) })
      .to_h.dig("data", "transactions")
  end

  test "lists a game's transactions newest first, one page at a time" do
    first_page = fetch(first: 1)
    assert_equal [ { "transactionType" => "SELL", "quantity" => 500 } ], first_page["nodes"]
    assert first_page.dig("pageInfo", "hasNextPage")

    second_page = fetch(first: 1, after: first_page.dig("pageInfo", "endCursor"))
    assert_equal [ { "transactionType" => "BUY", "quantity" => 500 } ], second_page["nodes"]
    assert_not second_page.dig("pageInfo", "hasNextPage")
  end

  test "excludes other games' transactions" do
    assert_empty StockTickerSchema.execute(QUERY, variables: { gameId: games(:waiting_game).id }).to_h.dig("data", "transactions", "nodes")
  end
end
