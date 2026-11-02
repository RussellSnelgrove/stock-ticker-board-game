# typed: false
# frozen_string_literal: true

module Types
  class PlayerType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :cash, Integer, null: false,
      description: "Cash on hand in cents (500_000 = $5,000)"
    field :status, Types::PlayerStatusType, null: false
    field :turn_position, Integer, null: false
    field :online, Boolean, null: false, description: "Whether the player has the game open"
    field :holdings, [ Types::HoldingType ], null: false
    field :portfolio_value, Integer, null: false, description: "Market value of all holdings in cents"
    field :current_net_worth, Integer, null: false, description: "Cash plus portfolio value in cents"
    field :net_worth, Integer, null: true,
      description: "Final net worth in cents (cash + portfolio value), set when game ends"
    field :final_rank, Integer, null: true,
      description: "Final rank at game end; tied players share the same rank"

    def holdings
      object.holdings.includes(game_stock: :stock).where("quantity > 0").order(:game_stock_id)
    end
  end
end
