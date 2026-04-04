# typed: true
# frozen_string_literal: true

require "test_helper"

class MessageTest < ActiveSupport::TestCase
  # Validations -----------------------------------------------------------

  test "valid fixture is valid" do
    assert messages(:hello).valid?
  end

  test "invalid without body" do
    msg = messages(:hello)
    msg.body = ""
    assert_not msg.valid?
    assert_includes msg.errors[:body], "can't be blank"
  end

  test "invalid when body exceeds 200 characters" do
    msg = messages(:hello)
    msg.body = "x" * 201
    assert_not msg.valid?
    assert msg.errors[:body].any?
  end

  test "valid at exactly 200 characters" do
    msg = messages(:hello)
    msg.body = "x" * 200
    assert msg.valid?
  end

  # Associations ----------------------------------------------------------

  test "belongs to user" do
    assert_equal users(:one), messages(:hello).user
  end

  test "belongs to game" do
    assert_equal games(:active_game), messages(:hello).game
  end
end
