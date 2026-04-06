# typed: false
# frozen_string_literal: true

module Mutations
  class StartGame < BaseMutation
    description "Start a game (host only). Transitions from waiting to in_progress, computes ends_at, and schedules the expiry job."

    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:)
      current_user = context[:current_user]
      return { game: nil, errors: [ "You must be logged in" ] } unless current_user

      game = Game.find_by(id: game_id)
      return { game: nil, errors: [ "Game not found" ] } unless game

      unless game.host_id == current_user.id
        return { game: nil, errors: [ "Only the host can start the game" ] }
      end

      game.start!
      GameClockExpiryJob.set(wait_until: game.ends_at).perform_later(game.id)

      { game: game, errors: [] }
    rescue RuntimeError => e
      { game: nil, errors: [ e.message ] }
    end
  end
end
