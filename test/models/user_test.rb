# typed: true
# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Validations -----------------------------------------------------------

  test "valid with display_name" do
    assert users(:one).valid?
  end

  test "invalid without display_name" do
    user = User.new(display_name: "")
    assert_not user.valid?
    assert_includes user.errors[:display_name], "can't be blank"
  end

  # Associations ----------------------------------------------------------

  test "has many players" do
    assert_includes users(:one).players, players(:player_one)
  end

  test "has many games through players" do
    assert_includes users(:one).games, games(:active_game)
  end

  test "has many messages" do
    assert_includes users(:one).messages, messages(:hello)
  end

  test "destroying user destroys dependent players and messages" do
    user = users(:two)
    assert_difference [ "Player.count", "Message.count" ], -1 do
      user.destroy
    end
  end
end
