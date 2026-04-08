# typed: false
# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_game, mutation: Mutations::CreateGame
    field :start_game, mutation: Mutations::StartGame
    field :join_game, mutation: Mutations::JoinGame
  end
end
