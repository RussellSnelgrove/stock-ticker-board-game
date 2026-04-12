# typed: false
# frozen_string_literal: true

module Types
  class GameType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :invite_code, String, null: false
    field :host, Types::UserType, null: false
    field :status, Types::GameStatusType, null: false
    field :current_turn, Integer, null: false
    field :duration, Integer, null: false,
      description: "Game duration in minutes (15, 30, 60, or 90)"
    field :starts_at, GraphQL::Types::ISO8601DateTime, null: true
    field :ends_at, GraphQL::Types::ISO8601DateTime, null: true
    field :remaining_time, Integer, null: true,
      description: "Seconds remaining when paused"
    field :rolls_remaining_this_turn, Integer, null: false
    field :game_stocks, [ Types::GameStockType ], null: false
    field :players, [ Types::PlayerType ], null: false
    field :active_player, Types::PlayerType, null: true
  end
end
