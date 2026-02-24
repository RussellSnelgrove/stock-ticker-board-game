# frozen_string_literal: true

module Types
  class GameTransactionType < Types::BaseObject
    field :id, ID, null: false
    field :player, Types::PlayerType, null: false
    field :game_stock, Types::GameStockType, null: false
    field :transaction_type, String, null: false
    field :quantity, Integer, null: false
    field :price_at_time, Integer, null: false
    field :total_amount, Integer, null: false
    field :turn_number, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
