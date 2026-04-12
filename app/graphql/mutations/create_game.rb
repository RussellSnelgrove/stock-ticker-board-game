# typed: false
# frozen_string_literal: true

module Mutations
  class CreateGame < BaseMutation
    description "Create a new game in waiting status. The clock does not start until StartGame is called."

    argument :name, String, required: true
    argument :duration, Integer, required: true,
      description: "Game duration in minutes. Must be one of: 15, 30, 60, 90."

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(name:, duration:)
      unless Game::DURATION_PRESETS.include?(duration)
        return { game: nil, errors: [ "Duration must be one of: #{Game::DURATION_PRESETS.join(', ')} minutes" ] }
      end

      current_user = context[:current_user]
      return { game: nil, errors: [ "You must be logged in to create a game" ] } unless current_user

      game = Game.new(name: name, duration: duration, host: current_user)

      if game.save
        initialize_game_stocks(game)
        add_host_as_player(game, current_user)
        { game: game, errors: [] }
      else
        { game: nil, errors: game.errors.full_messages }
      end
    end

    private

    def initialize_game_stocks(game)
      Stock.all.each do |stock|
        game.game_stocks.create!(stock: stock, current_price: 100)
      end
    end

    def add_host_as_player(game, user)
      game.players.create!(user: user, cash: 500_000, turn_position: 0, status: :active)
    end
  end
end
