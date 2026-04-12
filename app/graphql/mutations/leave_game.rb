# typed: false
# frozen_string_literal: true

module Mutations
  class LeaveGame < BaseMutation
    description "Drop out of a game while preserving state. The player can rejoin later via JoinGame."

    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:)
      current_user = context[:current_user]
      return { game: nil, errors: [ "You must be logged in" ] } unless current_user

      game = Game.find_by(id: game_id)
      return { game: nil, errors: [ "Game not found" ] } unless game

      player = game.players.find_by(user: current_user)
      return { game: nil, errors: [ "You are not in this game" ] } unless player
      return { game: nil, errors: [ "You have already left this game" ] } if player.dropped?

      player.update!(status: :dropped)

      { game: game, errors: [] }
    end
  end
end
