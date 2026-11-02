# typed: strict
# frozen_string_literal: true

# Players ranked by current net worth. Ties go to the earlier joiner (lower turn_position).
class Leaderboard
  extend T::Sig

  sig { params(game: Game).returns(T::Array[Player]) }
  def self.ranked_players(game)
    game.players.includes(:user, holdings: :game_stock).sort_by do |player|
      [ -player.current_net_worth, player.turn_position ]
    end
  end
end
