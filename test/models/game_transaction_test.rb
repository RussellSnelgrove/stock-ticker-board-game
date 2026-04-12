# typed: true
# frozen_string_literal: true

require "test_helper"

class GameTransactionTest < ActiveSupport::TestCase
  # Validations -----------------------------------------------------------

  test "valid fixture is valid" do
    assert game_transactions(:buy_grain).valid?
  end

  test "invalid with negative quantity" do
    gt = game_transactions(:buy_grain)
    gt.quantity = -1
    assert_not gt.valid?
    assert gt.errors[:quantity].any?
  end

  test "invalid with non-integer quantity" do
    gt = game_transactions(:buy_grain)
    gt.quantity = T.unsafe(1.5)
    assert_not gt.valid?
    assert gt.errors[:quantity].any?
  end

  test "invalid with negative price_at_time" do
    gt = game_transactions(:buy_grain)
    gt.price_at_time = -1
    assert_not gt.valid?
    assert gt.errors[:price_at_time].any?
  end

  test "invalid with non-integer price_at_time" do
    gt = game_transactions(:buy_grain)
    gt.price_at_time = T.unsafe(1.5)
    assert_not gt.valid?
    assert gt.errors[:price_at_time].any?
  end

  test "invalid with non-integer total_amount" do
    gt = game_transactions(:buy_grain)
    gt.total_amount = T.unsafe(1.5)
    assert_not gt.valid?
    assert gt.errors[:total_amount].any?
  end

  test "total_amount can be negative (sell at loss scenario)" do
    gt = game_transactions(:buy_grain)
    gt.total_amount = -100
    assert gt.valid?
  end

  test "invalid with negative turn_number" do
    gt = game_transactions(:buy_grain)
    gt.turn_number = -1
    assert_not gt.valid?
    assert gt.errors[:turn_number].any?
  end

  test "invalid transaction_type is rejected by validation" do
    gt = game_transactions(:buy_grain)
    gt.transaction_type = "unknown"
    assert_not gt.valid?
    assert gt.errors[:transaction_type].any?
  end

  test "all valid transaction types are accepted" do
    gt = game_transactions(:buy_grain)
    %i[buy sell dividend stock_split worthless_reset].each do |type|
      gt.transaction_type = type
      assert gt.valid?, "expected transaction_type #{type} to be valid"
    end
  end

  # Associations ----------------------------------------------------------

  test "belongs to player" do
    assert_equal players(:player_one), game_transactions(:buy_grain).player
  end

  test "belongs to game_stock" do
    assert_equal game_stocks(:grain_in_game_one), game_transactions(:buy_grain).game_stock
  end
end
