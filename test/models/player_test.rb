# typed: true
# frozen_string_literal: true

require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  # Validations -----------------------------------------------------------

  test "valid fixture is valid" do
    assert players(:player_one).valid?
  end

  test "invalid with negative cash" do
    player = players(:player_one)
    player.cash = -1
    assert_not player.valid?
    assert player.errors[:cash].any?
  end

  test "invalid with non-integer cash" do
    player = players(:player_one)
    player.cash = T.unsafe(1.5)
    assert_not player.valid?
    assert player.errors[:cash].any?
  end

  test "invalid with negative turn_position" do
    player = players(:player_one)
    player.turn_position = -1
    assert_not player.valid?
    assert player.errors[:turn_position].any?
  end

  test "invalid status is rejected by validation" do
    player = players(:player_one)
    player.status = "unknown"
    assert_not player.valid?
    assert player.errors[:status].any?
  end

  test "active and dropped are valid statuses" do
    player = players(:player_one)
    player.status = :active
    assert player.valid?
    player.status = :dropped
    assert player.valid?
  end

  # Associations ----------------------------------------------------------

  test "belongs to user" do
    assert_equal users(:one), players(:player_one).user
  end

  test "belongs to game" do
    assert_equal games(:active_game), players(:player_one).game
  end

  test "has many game_transactions" do
    assert_includes players(:player_one).game_transactions, game_transactions(:buy_grain)
  end

  test "has many dice_rolls" do
    assert_includes players(:player_one).dice_rolls, dice_rolls(:roll_one)
  end
end
