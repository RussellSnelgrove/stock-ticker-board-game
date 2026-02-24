# frozen_string_literal: true

module Mutations
  class JoinGame < BaseMutation
    argument :invite_code, String, required: true

    field :game, Types::GameType, null: true
    field :player, Types::PlayerType, null: true
    field :errors, [String], null: false

    def resolve(invite_code:)
      user = context[:current_user]
      return { game: nil, player: nil, errors: ["You must be logged in"] } unless user

      game = Game.find_by(invite_code: invite_code.upcase)
      return { game: nil, player: nil, errors: ["Game not found"] } unless game
      return { game: nil, player: nil, errors: ["Game is already completed"] } if game.completed?

      existing_player = game.players.find_by(user: user)

      if existing_player
        if existing_player.dropped?
          existing_player.update!(status: "active")
        end

        if game.paused? && game.host_id == user.id
          new_ends_at = Time.current + game.remaining_time.seconds
          game.update!(status: "in_progress", ends_at: new_ends_at, remaining_time: nil)
          GameClockExpiryJob.set(wait_until: new_ends_at).perform_later(game.id)
        end

        { game: game, player: existing_player, errors: [] }
      else
        next_position = (game.players.maximum(:turn_position) || -1) + 1
        player = game.players.create!(
          user: user,
          cash: Player::STARTING_CASH,
          status: "active",
          turn_position: next_position
        )
        { game: game, player: player, errors: [] }
      end
    end
  end
end
