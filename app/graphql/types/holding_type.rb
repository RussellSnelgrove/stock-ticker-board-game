# frozen_string_literal: true

module Types
  class HoldingType < Types::BaseObject
    field :id, ID, null: false
    field :game_stock, Types::GameStockType, null: false
    field :quantity, Integer, null: false
    field :lots, Integer, null: false
    field :value, Integer, null: false, description: "Current value in dollars"
  end
end
