# frozen_string_literal: true

module Types
  class PlayerType < Types::BaseObject
    field :id, ID, null: false
    field :user_id, ID, null: false
    field :display_name, String, null: false
    field :cash, Integer, null: false
    field :status, String, null: false
    field :turn_position, Integer, null: false
    field :net_worth, Integer, null: false
    field :holdings, [Types::HoldingType], null: false

    def display_name
      object.user.display_name
    end

    def holdings
      object.holdings.includes(:game_stock)
    end
  end
end
