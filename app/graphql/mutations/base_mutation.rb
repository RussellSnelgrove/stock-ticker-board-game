# typed: strict
# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    extend T::Sig

    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    private

    sig { returns(User) }
    def current_user!
      context[:current_user] || raise(GameRuleError, "You must be logged in")
    end

    sig { params(game_id: T.any(String, Integer)).returns(Game) }
    def find_game!(game_id)
      Game.find_by(id: game_id) || raise(GameRuleError, "Game not found")
    end

    sig { params(game: Game).returns(Player) }
    def find_player!(game)
      game.players.find_by(user: current_user!) || raise(GameRuleError, "You are not in this game")
    end
  end
end
