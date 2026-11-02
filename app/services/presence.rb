# typed: strict
# frozen_string_literal: true

# Marks a user's players online or offline in every game that is not over.
module Presence
  extend T::Sig

  sig { params(user: User, online: T::Boolean).void }
  def self.update(user, online:)
    user.players.joins(:game).where.not(games: { status: :completed }).includes(:game).find_each do |player|
      next if player.online == online

      player.update!(online: online)
      GameEvents.presence_changed(T.must(player.game), player)
    end
  end
end
