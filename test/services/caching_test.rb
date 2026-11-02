# typed: true
# frozen_string_literal: true

require "test_helper"

class CachingTest < ActiveSupport::TestCase
  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown { Rails.cache = @original_cache }

  def ranked_names(game)
    Leaderboard.ranked_players(game).map { |p| T.must(p.user).display_name }
  end

  test "the leaderboard is served from the cache until net worth changes" do
    game = games(:active_game)
    assert_equal %w[Alice Bob Carol], ranked_names(game)

    # A write that bypasses callbacks does not touch the game, so the cached ranking stays.
    players(:dropped_player).update_columns(cash: 9_000_000)
    assert_equal %w[Alice Bob Carol], ranked_names(game)

    # A normal write touches the game and the ranking is recomputed.
    players(:dropped_player).update!(cash: 9_000_001)
    assert_equal %w[Carol Alice Bob], ranked_names(game)
  end

  test "a trade refreshes the leaderboard even when the caller holds a stale Game" do
    game = games(:active_game)
    game.update!(rolls_remaining_this_turn: 0)
    assert_equal %w[Alice Bob Carol], ranked_names(game)

    stale = Game.find(game.id)
    TradingService.new(game: game, player: players(:player_two)).buy!(game_stock_id: game_stocks(:grain_in_game_one).id, quantity: 3000)
    game_stocks(:grain_in_game_one).update!(current_price: 150)

    # Bob: 80_000 cash + 3000 grain × 150 + 1000 bonds × 80 = 610_000. Alice: 500_000 + 500 × 150 = 575_000
    assert_equal %w[Bob Alice Carol], ranked_names(stale)
  end

  test "the lobby listing is cached and expires when a game is created" do
    before = Game.listed_ids
    assert_includes before, games(:waiting_game).id

    game = Game.create!(name: "Fresh", host: users(:one), duration: 15)
    assert_equal game.id, Game.listed_ids.first
  end

  test "the lobby listing expires when a game completes" do
    assert_includes Game.listed_ids, games(:active_game).id
    games(:active_game).complete!
    assert_not_includes Game.listed_ids, games(:active_game).id
  end

  test "the lobby listing expires when a player joins" do
    Game.listed_ids
    Rails.cache.write(Game::LISTING_CACHE_KEY, [ 0 ])
    games(:waiting_game).players.create!(user: users(:two), turn_position: 1)
    assert_includes Game.listed_ids, games(:waiting_game).id
  end
end
