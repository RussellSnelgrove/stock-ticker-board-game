# typed: true
# frozen_string_literal: true

require "test_helper"

class HoldingTest < ActiveSupport::TestCase
  test "valid fixture is valid" do
    assert holdings(:player_one_grain).valid?
  end

  test "quantity must be a multiple of 500" do
    holding = holdings(:player_one_grain)
    holding.quantity = 750
    assert_not holding.valid?
    assert_includes holding.errors[:quantity], "must be a multiple of 500"
  end

  test "quantity cannot be negative" do
    holding = holdings(:player_one_grain)
    holding.quantity = -500
    assert_not holding.valid?
  end

  test "a player has one holding per stock" do
    duplicate = Holding.new(player: players(:player_one), game_stock: game_stocks(:grain_in_game_one), quantity: 500)
    assert_not duplicate.valid?
  end

  test "value is quantity times current price" do
    assert_equal 80_000, holdings(:player_two_bonds).value
  end

  test "player net worth is cash plus holdings at current prices" do
    assert_equal 380_000 + 80_000, players(:player_two).current_net_worth
  end
end
