# frozen_string_literal: true

module Mutations
  class LeaveGame < BaseMutation
    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [String], null: false

    def resolve(game_id:)
      user = context[:current_user]
      return { game: nil, errors: ["You must be logged in"] } unless user

      game = Game.find_by(id: game_id)
      return { game: nil, errors: ["Game not found"] } unless game

      player = game.players.find_by(user: user)
      return { game: nil, errors: ["You are not in this game"] } unless player

      player.update!(status: "dropped")

      { game: game, errors: [] }
    end
  end
end
