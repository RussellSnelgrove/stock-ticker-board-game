# typed: strict
# frozen_string_literal: true

# Players ranked by current net worth. Ties go to the earlier joiner (lower turn_position).
#
# The ranking is cached under the game's updated_at. Every write that can change net worth
# (cash, holdings, prices) touches the game row first, so a cached ranking is never stale.
class Leaderboard
  extend T::Sig

  sig { params(game: Game).returns(T::Array[Player]) }
  def self.ranked_players(game)
    # Read the version from the database: the caller's Game may predate a touch.
    version = Game.where(id: game.id).pick(:updated_at)&.to_f
    ids = Rails.cache.fetch([ "leaderboard", game.id, version ]) { rank(game).map(&:id) }
    by_id = game.players.includes(:user).index_by(&:id)
    ids.filter_map { |id| by_id[id] }
  end

  sig { params(game: Game).returns(T::Array[Player]) }
  def self.rank(game)
    game.players.includes(holdings: :game_stock).sort_by do |player|
      [ -player.current_net_worth, player.turn_position ]
    end
  end
  private_class_method :rank
end
