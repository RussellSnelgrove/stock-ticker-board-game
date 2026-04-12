# typed: true
# frozen_string_literal: true

require "test_helper"

class DiceRollTest < ActiveSupport::TestCase
  # Validations -----------------------------------------------------------

  test "valid fixture is valid" do
    assert dice_rolls(:roll_one).valid?
  end

  test "invalid with negative turn_number" do
    roll = dice_rolls(:roll_one)
    roll.turn_number = -1
    assert_not roll.valid?
    assert roll.errors[:turn_number].any?
  end

  test "invalid with non-integer turn_number" do
    roll = dice_rolls(:roll_one)
    roll.turn_number = T.unsafe(1.5)
    assert_not roll.valid?
    assert roll.errors[:turn_number].any?
  end

  test "invalid with amount not in valid set" do
    roll = dice_rolls(:roll_one)
    roll.amount = 15
    assert_not roll.valid?
    assert roll.errors[:amount].any?
  end

  test "all valid amounts are accepted" do
    roll = dice_rolls(:roll_one)
    DiceRoll::VALID_AMOUNTS.each do |amt|
      roll.amount = amt
      assert roll.valid?, "expected amount #{amt} to be valid"
    end
  end

  test "invalid direction is rejected by validation" do
    roll = dice_rolls(:roll_one)
    roll.direction = "sideways"
    assert_not roll.valid?
    assert roll.errors[:direction].any?
  end

  test "all valid directions are accepted" do
    roll = dice_rolls(:roll_one)
    %i[up down dividend].each do |dir|
      roll.direction = dir
      assert roll.valid?, "expected direction #{dir} to be valid"
    end
  end

  # Associations ----------------------------------------------------------

  test "belongs to game" do
    assert_equal games(:active_game), dice_rolls(:roll_one).game
  end

  test "belongs to player" do
    assert_equal players(:player_one), dice_rolls(:roll_one).player
  end

  test "belongs to stock_rolled" do
    assert_equal stocks(:grain), dice_rolls(:roll_one).stock_rolled
  end
end
