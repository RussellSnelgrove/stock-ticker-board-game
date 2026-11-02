# typed: false
# frozen_string_literal: true

module Types
  class GameType < Types::BaseObject
    RECENT_MESSAGE_LIMIT = 50

    field :id, ID, null: false
    field :name, String, null: false
    field :invite_code, String, null: false
    field :host, Types::UserType, null: false
    field :status, Types::GameStatusType, null: false
    field :current_turn, Integer, null: false, description: "Number of turns completed"
    field :duration, Integer, null: false,
      description: "Game duration in minutes (15, 30, 60, or 90)"
    field :starts_at, GraphQL::Types::ISO8601DateTime, null: true
    field :ends_at, GraphQL::Types::ISO8601DateTime, null: true
    field :remaining_time, Integer, null: true,
      description: "Seconds remaining when paused"
    field :seconds_remaining, Integer, null: true,
      description: "Seconds left on the clock (running or paused)"
    field :rolls_remaining_this_turn, Integer, null: false
    field :solo, Boolean, null: false, method: :solo?
    field :game_stocks, [ Types::GameStockType ], null: false
    field :players, [ Types::PlayerType ], null: false
    field :active_player, Types::PlayerType, null: true
    field :leaderboard, [ Types::PlayerType ], null: false,
      description: "Players ranked by current net worth; ties go to the earlier joiner"
    field :last_dice_roll, Types::DiceRollType, null: true
    field :messages, [ Types::MessageType ], null: false,
      description: "The #{RECENT_MESSAGE_LIMIT} most recent chat messages, oldest first"
    field :viewer, Types::PlayerType, null: true,
      description: "The current user's player in this game, if any"

    def game_stocks
      object.game_stocks.joins(:stock).includes(:stock).merge(Stock.in_board_order)
    end

    def players
      object.players.includes(:user).order(:turn_position)
    end

    def active_player
      object.active_player if object.in_progress? || object.paused?
    end

    def leaderboard
      Leaderboard.ranked_players(object)
    end

    def last_dice_roll
      object.dice_rolls.order(:id).last
    end

    def messages
      object.messages.includes(:user).order(id: :desc).limit(RECENT_MESSAGE_LIMIT).reverse
    end

    def viewer
      user = context[:current_user]
      object.players.find_by(user: user) if user
    end
  end
end
