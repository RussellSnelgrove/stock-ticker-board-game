# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::RollDiceTest < ActiveSupport::TestCase
  MUTATION = <<~GQL
    mutation($gameId: ID!) {
      rollDice(input: { gameId: $gameId }) {
        roll {
          outcome
          previousPrice
          newPrice
          diceRoll { direction amount stockRolled { name symbol } }
          gameStock { id currentPrice }
        }
        rollsRemaining
        game { rollsRemainingThisTurn }
        errors
      }
    }
  GQL

  def roll_as(user, game = games(:active_game))
    StockTickerSchema.execute(MUTATION, variables: { gameId: game.id }, context: { current_user: user })
      .to_h.dig("data", "rollDice")
  end

  test "the active player rolls and sees the result" do
    data = roll_as(users(:two))

    assert_empty data["errors"]
    assert_equal 1, data["rollsRemaining"]
    assert_equal 1, data.dig("game", "rollsRemainingThisTurn")
    assert_includes %w[UP DOWN SPLIT WORTHLESS DIVIDEND DIVIDEND_SKIPPED], data.dig("roll", "outcome")
    assert_includes Stock::NAMES, data.dig("roll", "diceRoll", "stockRolled", "name")
  end

  test "rolling records a DiceRoll" do
    assert_difference "DiceRoll.count", 1 do
      roll_as(users(:two))
    end
  end

  test "another player cannot roll" do
    data = roll_as(users(:one))
    assert_nil data["roll"]
    assert_equal [ "It is not your turn" ], data["errors"]
  end

  test "a third roll in one turn is rejected" do
    2.times { roll_as(users(:two)) }
    assert_equal [ "You have no rolls left this turn" ], roll_as(users(:two))["errors"]
  end

  test "rolling requires a logged-in player in the game" do
    assert_equal [ "You must be logged in" ], roll_as(nil)["errors"]
    assert_equal [ "You are not in this game" ], roll_as(User.create!(display_name: "Eve"))["errors"]
  end
end
