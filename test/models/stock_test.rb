# typed: true
# frozen_string_literal: true

require "test_helper"

class StockTest < ActiveSupport::TestCase
  # Validations -----------------------------------------------------------

  test "valid with a known name" do
    assert stocks(:grain).valid?
  end

  test "invalid without name" do
    stock = Stock.new(name: "")
    assert_not stock.valid?
    assert_includes stock.errors[:name], "can't be blank"
  end

  test "invalid with an unknown name" do
    stock = Stock.new(name: "Cheese")
    assert_not stock.valid?
    assert_includes stock.errors[:name], "is not included in the list"
  end

  test "all six commodity names are valid" do
    Stock::NAMES.each do |name|
      assert Stock.new(name: name).valid?, "expected #{name} to be valid"
    end
  end

  # Associations ----------------------------------------------------------

  test "has many game_stocks" do
    assert_includes stocks(:grain).game_stocks, game_stocks(:grain_in_game_one)
  end

  test "destroying stock destroys dependent game_stocks" do
    # Use bonds: it has a game_stock fixture but is not referenced by any dice_roll,
    # so the Foreign Key constraint on dice_rolls.stock_rolled_id won't block the delete.
    assert_difference "GameStock.count", -1 do
      stocks(:bonds).destroy
    end
  end
end
