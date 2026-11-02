# typed: strict
# frozen_string_literal: true

class GameClockExpiryJob < ApplicationJob
  extend T::Sig

  sig { params(game_id: Integer).void }
  def perform(game_id)
    game = Game.find_by(id: game_id)
    return unless game&.in_progress?
    # A pause and resume pushes ends_at later and schedules a new job; ignore the stale one.
    return if T.must(game.ends_at) > Time.current

    game.with_lock do
      compute_net_worths(game)
      assign_ranks(game)
      game.complete!
    end
    GameEvents.game_ended(game)
  end

  private

  sig { params(game: Game).void }
  def compute_net_worths(game)
    game.players.each do |player|
      player.update_column(:net_worth, player.current_net_worth)
    end
  end

  # Assigns final_rank to each player. Players with equal net_worth share the same rank;
  # within a tie, earlier turn_position is listed first (ranks are shared, not skipped).
  sig { params(game: Game).void }
  def assign_ranks(game)
    players = game.players.reload.sort_by { |p| [ -p.net_worth.to_i, p.turn_position ] }

    rank = T.let(1, Integer)
    players.each_with_index do |player, i|
      if i > 0 && players[i - 1].net_worth != player.net_worth
        rank = i + 1
      end
      player.update_column(:final_rank, rank)
    end
  end
end
