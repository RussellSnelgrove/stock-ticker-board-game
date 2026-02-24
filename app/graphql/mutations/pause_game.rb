# frozen_string_literal: true

module Mutations
  class PauseGame < BaseMutation
    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [String], null: false

    def resolve(game_id:)
      user = context[:current_user]
      return { game: nil, errors: ["You must be logged in"] } unless user

      game = Game.find_by(id: game_id)
      return { game: nil, errors: ["Game not found"] } unless game
      return { game: nil, errors: ["Only the host can pause the game"] } unless game.host_id == user.id
      return { game: nil, errors: ["Game must be in progress to pause"] } unless game.in_progress?
      return { game: nil, errors: ["Only solo games can be paused"] } unless game.players.active.count == 1

      seconds_left = [(game.ends_at - Time.current).to_i, 0].max
      game.update!(status: "paused", remaining_time: seconds_left, ends_at: nil)

      { game: game, errors: [] }
    end
  end
end
