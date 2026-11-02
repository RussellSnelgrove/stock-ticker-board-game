# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::EndTurnTest < ActiveSupport::TestCase
  MUTATION = <<~GQL
    mutation($gameId: ID!) {
      endTurn(input: { gameId: $gameId }) {
        game { currentTurn rollsRemainingThisTurn activePlayer { id } }
        errors
      }
    }
  GQL

  def end_turn_as(user)
    StockTickerSchema.execute(MUTATION, variables: { gameId: games(:active_game).id }, context: { current_user: user })
      .to_h.dig("data", "endTurn")
  end

  test "after both rolls, play passes to the next active player" do
    games(:active_game).update!(rolls_remaining_this_turn: 0)
    data = end_turn_as(users(:two))

    assert_empty data["errors"]
    assert_equal 4, data.dig("game", "currentTurn")
    assert_equal 2, data.dig("game", "rollsRemainingThisTurn")
    assert_equal players(:player_one).id.to_s, data.dig("game", "activePlayer", "id")
  end

  test "ending the turn before both rolls is rejected" do
    games(:active_game).update!(rolls_remaining_this_turn: 1)
    assert_equal [ "Finish both rolls before ending your turn" ], end_turn_as(users(:two))["errors"]
  end

  test "only the active player can end the turn" do
    games(:active_game).update!(rolls_remaining_this_turn: 0)
    assert_equal [ "It is not your turn" ], end_turn_as(users(:one))["errors"]
  end
end
