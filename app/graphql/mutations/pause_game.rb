# typed: false
# frozen_string_literal: true

module Mutations
  class PauseGame < BaseMutation
    description "Pause a solo game. Stores the time left and stops the clock."

    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:)
      game = find_game!(game_id)
      find_player!(game)
      game.pause!

      { game: game, errors: [] }
    rescue GameRuleError => e
      { game: nil, errors: [ e.message ] }
    end
  end
end
