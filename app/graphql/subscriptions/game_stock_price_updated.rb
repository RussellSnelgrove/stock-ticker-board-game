# typed: false
# frozen_string_literal: true

module Subscriptions
  class GameStockPriceUpdated < BaseSubscription
    description "Fired when a roll changes or resets a stock's price."

    field :game_stock, Types::GameStockType, null: false
    field :previous_price, Integer, null: false
  end
end
