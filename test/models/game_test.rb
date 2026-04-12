# typed: true
# frozen_string_literal: true

require "test_helper"

class GameTest < ActiveSupport::TestCase
  # Validations -----------------------------------------------------------

  test "valid fixture is valid" do
    assert games(:waiting_game).valid?
  end

  test "invalid without name" do
    game = games(:waiting_game)
    game.name = ""
    assert_not game.valid?
    assert_includes game.errors[:name], "can't be blank"
  end

  test "invalid without invite_code" do
    game = games(:waiting_game)
    game.invite_code = ""
    assert_not game.valid?
    assert_includes game.errors[:invite_code], "can't be blank"
  end

  test "invite_code must be exactly 6 characters" do
    game = games(:waiting_game)
    game.invite_code = "ABC"
    assert_not game.valid?
    assert game.errors[:invite_code].any?
  end

  test "invite_code must be unique" do
    game = Game.new(
      name: "Dup Game",
      invite_code: games(:waiting_game).invite_code,
      host: users(:two),
      duration: 30
    )
    assert_not game.valid?
    assert_includes game.errors[:invite_code], "has already been taken"
  end

  test "duration must be a preset value" do
    game = games(:waiting_game)
    game.duration = 45
    assert_not game.valid?
    assert game.errors[:duration].any?
  end

  test "all duration presets are valid" do
    Game::DURATION_PRESETS.each do |minutes|
      game = games(:waiting_game)
      game.duration = minutes
      assert game.valid?, "expected duration #{minutes} to be valid"
    end
  end

  test "current_turn cannot be negative" do
    game = games(:waiting_game)
    game.current_turn = -1
    assert_not game.valid?
    assert game.errors[:current_turn].any?
  end

  test "rolls_remaining_this_turn cannot exceed ROLLS_PER_TURN" do
    game = games(:waiting_game)
    game.rolls_remaining_this_turn = Game::ROLLS_PER_TURN + 1
    assert_not game.valid?
    assert game.errors[:rolls_remaining_this_turn].any?
  end

  test "rolls_remaining_this_turn cannot be negative" do
    game = games(:waiting_game)
    game.rolls_remaining_this_turn = -1
    assert_not game.valid?
    assert game.errors[:rolls_remaining_this_turn].any?
  end

  test "invalid status is rejected by validation" do
    game = games(:waiting_game)
    game.status = "nonsense"
    assert_not game.valid?
    assert game.errors[:status].any?
  end

  # Associations ----------------------------------------------------------

  test "belongs to host" do
    assert_equal users(:one), games(:active_game).host
  end

  test "has many game_stocks" do
    assert_includes games(:active_game).game_stocks, game_stocks(:grain_in_game_one)
  end

  test "has many players" do
    assert_includes games(:active_game).players, players(:player_one)
  end

  test "has many dice_rolls" do
    assert_includes games(:active_game).dice_rolls, dice_rolls(:roll_one)
  end

  test "has many messages" do
    assert_includes games(:active_game).messages, messages(:hello)
  end

  # State transitions -----------------------------------------------------

  test "start! transitions waiting game to in_progress" do
    game = games(:waiting_game)
    game.start!
    assert game.in_progress?
    assert_not_nil game.starts_at
    assert_not_nil game.ends_at
    assert T.must(game.ends_at) > T.must(game.starts_at)
  end

  test "start! raises when game is not waiting" do
    assert_raises(RuntimeError) { games(:active_game).start! }
  end

  test "pause! transitions in_progress game to paused" do
    game = games(:active_game)
    game.pause!
    assert game.paused?
    assert_not_nil game.remaining_time
  end

  test "pause! raises when game is not in_progress" do
    assert_raises(RuntimeError) { games(:waiting_game).pause! }
  end

  test "resume! transitions paused game back to in_progress" do
    game = games(:active_game)
    game.pause!
    game.resume!
    assert game.in_progress?
    assert_nil game.remaining_time
  end

  test "resume! raises when game is not paused" do
    assert_raises(RuntimeError) { games(:active_game).resume! }
  end

  test "complete! transitions in_progress game to completed" do
    game = games(:active_game)
    game.complete!
    assert game.completed?
  end

  test "complete! raises when game is not in_progress" do
    assert_raises(RuntimeError) { games(:waiting_game).complete! }
  end

  # Computed --------------------------------------------------------------

  test "active_player returns nil when game is not in_progress" do
    assert_nil games(:waiting_game).active_player
  end

  test "active_player returns the player whose turn it is" do
    game = games(:active_game)
    # current_turn=3, 2 active players → 3 % 2 = 1 → player at turn_position 1
    assert_equal players(:player_two), game.active_player
  end

  test "active_player returns nil when there are no active players" do
    game = games(:active_game)
    game.players.update_all(status: "dropped")
    assert_nil game.active_player
  end

  # Callbacks -------------------------------------------------------------

  test "invite_code is auto-generated on create" do
    game = Game.create!(name: "Auto Code Game", host: users(:one), duration: 15)
    assert_match(/\A[A-Z0-9]{6}\z/, game.invite_code)
  end
end
