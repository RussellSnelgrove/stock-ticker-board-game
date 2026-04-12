# typed: false
# frozen_string_literal: true

module Types
  class DiceRollType < Types::BaseObject
    field :id, ID, null: false
    field :player, Types::PlayerType, null: false
    field :stock_rolled, Types::StockType, null: false
    field :turn_number, Integer, null: false
    field :direction, Types::DiceDirectionType, null: false
    field :amount, Integer, null: false,
      description: "Price change amount in cents (5, 10, or 20)"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
