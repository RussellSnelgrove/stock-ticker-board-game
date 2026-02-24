# frozen_string_literal: true

module Types
  class DiceRollType < Types::BaseObject
    field :id, ID, null: false
    field :stock, Types::StockType, null: false
    field :direction, String, null: false
    field :amount, Integer, null: false, description: "Amount in cents"
    field :turn_number, Integer, null: false
    field :player, Types::PlayerType, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
