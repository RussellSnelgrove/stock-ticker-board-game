# typed: true
# frozen_string_literal: true

require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connecting with a session marks the user's players online" do
    connect session: { user_id: users(:one).id }

    assert_equal users(:one), connection.current_user
    assert players(:player_one).reload.online
    assert players(:waiting_game_host).reload.online
  end

  test "disconnecting marks the user's players offline" do
    connect session: { user_id: users(:one).id }
    disconnect

    assert_not players(:player_one).reload.online
  end

  test "connections without a known user are rejected" do
    assert_reject_connection { connect }
    assert_reject_connection { connect session: { user_id: 0 } }
  end
end
