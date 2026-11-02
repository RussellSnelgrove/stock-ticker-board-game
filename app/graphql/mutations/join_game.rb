# typed: false
# frozen_string_literal: true

module Mutations
  class JoinGame < BaseMutation
    description "Join a game via invite code. Restores a previously dropped player's state, or creates a new Player with $5,000 cash at the end of the turn order."

    argument :invite_code, String, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(invite_code:)
      user = current_user!
      game = Game.find_by(invite_code: invite_code.strip.upcase)
      raise GameRuleError, "Game not found" unless game
      raise GameRuleError, "Game has already ended" if game.completed?

      player = game.with_lock do
        existing = game.players.find_by(user: user)
        if existing
          # Rejoining a paused solo game restores the player; the clock stays stopped until ResumeGame.
          existing.update!(status: :active) if existing.dropped?
          existing
        else
          raise GameRuleError, "This solo game is paused" if game.paused?

          next_position = (game.players.maximum(:turn_position) || -1) + 1
          game.players.create!(user: user, cash: Player::STARTING_CASH, turn_position: next_position, status: :active)
        end
      end

      had_turn = game.active_player_id
      game.assign_turn_if_vacant!
      GameEvents.presence_changed(game, player)
      GameEvents.turn_changed(game) if game.active_player_id != had_turn

      { game: game, errors: [] }
    rescue GameRuleError => e
      { game: nil, errors: [ e.message ] }
    end
  end
end
