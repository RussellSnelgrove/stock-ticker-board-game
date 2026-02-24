# frozen_string_literal: true

module Types
  class GameStockType < Types::BaseObject
    field :id, ID, null: false
    field :stock, Types::StockType, null: false
    field :current_price, Integer, null: false, description: "Price in cents (100 = $1.00)"
    field :price_dollars, Float, null: false
    field :name, String, null: false
    field :symbol, String, null: false
    field :color, String, null: false
    field :lot_cost, Integer, null: false, description: "Cost of 500 shares in dollars"
  end
end
