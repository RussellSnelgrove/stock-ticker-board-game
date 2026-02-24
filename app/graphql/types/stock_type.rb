# frozen_string_literal: true

module Types
  class StockType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :symbol, String, null: false
    field :color, String, null: false
  end
end
