# typed: false
# frozen_string_literal: true

module Types
  class HoldingType < Types::BaseObject
    field :id, ID, null: false
    field :game_stock, Types::GameStockType, null: false
    field :quantity, Integer, null: false, description: "Shares held (multiples of 500)"
    field :value, Integer, null: false, description: "Current market value in cents"
  end
end
