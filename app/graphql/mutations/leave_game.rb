# typed: false
# frozen_string_literal: true

module Mutations
  class LeaveGame < BaseMutation
    description "Drop out of a game while preserving state. If it is your turn, any remaining rolls are made for you and play passes on. You can rejoin later via JoinGame."

    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:)
      game = find_game!(game_id)
      player = find_player!(game)
      raise GameRuleError, "You have already left this game" if player.dropped?

      rolls = []
      had_turn = T.let(false, T::Boolean)
      game.with_lock do
        had_turn = game.clock_running? && game.active_player_id == player.id
        if had_turn
          service = DiceRollingService.new(game: game, player: player)
          rolls << service.roll! while game.rolls_remaining_this_turn.positive?
        end
        player.update!(status: :dropped)
        game.advance_turn! if had_turn
      end

      rolls.each { |roll| GameEvents.dice_rolled(game, roll) }
      GameEvents.presence_changed(game, player)
      GameEvents.turn_changed(game) if had_turn

      { game: game, errors: [] }
    rescue GameRuleError => e
      { game: nil, errors: [ e.message ] }
    end
  end
end
