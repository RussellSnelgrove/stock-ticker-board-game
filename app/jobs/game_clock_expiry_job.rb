# typed: strict
# frozen_string_literal: true

class GameClockExpiryJob < ApplicationJob
  extend T::Sig

  sig { params(game_id: Integer).void }
  def perform(game_id)
    game = Game.find_by(id: game_id)
    return unless game&.in_progress?

    game.complete!
  end
end
