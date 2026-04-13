# typed: false
# frozen_string_literal: true

module Types
  class GameStockType < Types::BaseObject
    field :id, ID, null: false
    field :stock, Types::StockType, null: false
    field :current_price, Integer, null: false,
      description: "Current price in cents (100 = $1.00)"
  end
end
