# typed: false
# frozen_string_literal: true

module Mutations
  class StartGame < BaseMutation
    description "Start a game (host only). Transitions from waiting to in_progress, computes ends_at, and schedules the expiry job."

    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:)
      user = current_user!
      game = find_game!(game_id)
      raise GameRuleError, "Only the host can start the game" unless game.host_id == user.id
      raise GameRuleError, "Cannot start a game with no players" if game.players.active.empty?

      game.start!
      GameClockExpiryJob.set(wait_until: game.ends_at).perform_later(game.id)
      GameEvents.game_started(game)

      { game: game, errors: [] }
    rescue GameRuleError => e
      { game: nil, errors: [ e.message ] }
    end
  end
end
