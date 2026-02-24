# frozen_string_literal: true

module Mutations
  class CreateGame < BaseMutation
    argument :name, String, required: true
    argument :duration, Integer, required: true, description: "Game duration in minutes"

    field :game, Types::GameType, null: true
    field :errors, [String], null: false

    def resolve(name:, duration:)
      user = context[:current_user]
      return { game: nil, errors: ["You must be logged in"] } unless user

      game = Game.new(
        name: name,
        duration: duration,
        status: "waiting",
        current_turn: 0,
        host: user
      )

      if game.save
        game.players.create!(
          user: user,
          cash: Player::STARTING_CASH,
          status: "active",
          turn_position: 0
        )
        { game: game, errors: [] }
      else
        { game: nil, errors: game.errors.full_messages }
      end
    end
  end
end
