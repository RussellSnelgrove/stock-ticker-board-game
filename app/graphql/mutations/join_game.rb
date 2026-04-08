# typed: false
# frozen_string_literal: true

module Mutations
  class JoinGame < BaseMutation
    description "Join a game via invite code. Restores a previously dropped player's state, or creates a new Player with $5,000 cash."

    argument :invite_code, String, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(invite_code:)
      current_user = context[:current_user]
      return { game: nil, errors: [ "You must be logged in to join a game" ] } unless current_user

      game = Game.find_by(invite_code: invite_code.upcase)
      return { game: nil, errors: [ "Game not found" ] } unless game
      return { game: nil, errors: [ "Game has already ended" ] } if game.completed?

      existing = game.players.find_by(user: current_user)

      if existing
        existing.update!(status: :active) if existing.dropped?
      else
        next_position = (game.players.maximum(:turn_position) || -1) + 1
        game.players.create!(
          user: current_user,
          cash: 500_000,
          turn_position: next_position,
          status: :active
        )
      end

      { game: game, errors: [] }
    end
  end
end
