# typed: true
# frozen_string_literal: true

require "test_helper"

class GameStockTest < ActiveSupport::TestCase
  # Validations -----------------------------------------------------------

  test "valid fixture is valid" do
    assert game_stocks(:grain_in_game_one).valid?
  end

  test "invalid with negative price" do
    gs = game_stocks(:grain_in_game_one)
    gs.current_price = -1
    assert_not gs.valid?
    assert gs.errors[:current_price].any?
  end

  test "invalid with price above 200" do
    gs = game_stocks(:grain_in_game_one)
    gs.current_price = 201
    assert_not gs.valid?
    assert gs.errors[:current_price].any?
  end

  test "valid at price boundary 0" do
    gs = game_stocks(:grain_in_game_one)
    gs.current_price = 0
    assert gs.valid?
  end

  test "valid at price boundary 200" do
    gs = game_stocks(:grain_in_game_one)
    gs.current_price = 200
    assert gs.valid?
  end

  test "invalid with non-integer price" do
    gs = game_stocks(:grain_in_game_one)
    gs.current_price = T.unsafe(1.5)
    assert_not gs.valid?
    assert gs.errors[:current_price].any?
  end

  # Associations ----------------------------------------------------------

  test "belongs to game" do
    assert_equal games(:active_game), game_stocks(:grain_in_game_one).game
  end

  test "belongs to stock" do
    assert_equal stocks(:grain), game_stocks(:grain_in_game_one).stock
  end

  test "has many game_transactions" do
    assert_includes game_stocks(:grain_in_game_one).game_transactions, game_transactions(:buy_grain)
  end
end
