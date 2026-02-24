# frozen_string_literal: true

module Types
  class GameType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :invite_code, String, null: false
    field :status, String, null: false
    field :current_turn, Integer, null: true
    field :duration, Integer, null: false, description: "Game duration in minutes"
    field :starts_at, GraphQL::Types::ISO8601DateTime, null: true
    field :ends_at, GraphQL::Types::ISO8601DateTime, null: true
    field :time_remaining, Integer, null: false, description: "Seconds remaining"
    field :host_id, ID, null: false
    field :host_name, String, null: false
    field :players, [Types::PlayerType], null: false
    field :game_stocks, [Types::GameStockType], null: false
    field :active_player, Types::PlayerType, null: true
    field :player_count, Integer, null: false
    field :rolls_remaining_this_turn, Integer, null: false

    def host_name
      object.host.display_name
    end

    def players
      object.players.by_turn_order.includes(:user, holdings: :game_stock)
    end

    def game_stocks
      object.game_stocks.includes(:stock).order(:stock_id)
    end

    def player_count
      object.players.count
    end
  end
end
