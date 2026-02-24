# frozen_string_literal: true

module Mutations
  class StartGame < BaseMutation
    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [String], null: false

    def resolve(game_id:)
      user = context[:current_user]
      return { game: nil, errors: ["You must be logged in"] } unless user

      game = Game.find_by(id: game_id)
      return { game: nil, errors: ["Game not found"] } unless game
      return { game: nil, errors: ["Only the host can start the game"] } unless game.host_id == user.id
      return { game: nil, errors: ["Game is not in waiting status"] } unless game.waiting?

      now = Time.current
      game.update!(
        status: "in_progress",
        starts_at: now,
        ends_at: now + game.duration.minutes
      )

      GameClockExpiryJob.set(wait_until: game.ends_at).perform_later(game.id)

      StockTickerSchema.subscriptions.trigger(:game_started, { game_id: game.id }, { game: game })

      { game: game, errors: [] }
    end
  end
end
