# typed: false
# frozen_string_literal: true

module Mutations
  class ResumeGame < BaseMutation
    description "Resume a paused solo game. Restarts the clock with the time that was left."

    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:)
      game = find_game!(game_id)
      find_player!(game)
      game.resume!
      GameClockExpiryJob.set(wait_until: game.ends_at).perform_later(game.id)

      { game: game, errors: [] }
    rescue GameRuleError => e
      { game: nil, errors: [ e.message ] }
    end
  end
end
