# typed: strict
# frozen_string_literal: true

class GameTransaction < ApplicationRecord
  extend T::Sig

  belongs_to :player
  belongs_to :game_stock

  # Note: "split" conflicts with ActiveRecord::Relation#split, so we use
  # "stock_split" as both the Ruby enum key and the DB string value.
  enum :transaction_type, {
    buy: "buy",
    sell: "sell",
    dividend: "dividend",
    stock_split: "stock_split",
    worthless_reset: "worthless_reset"
  }, validate: true

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price_at_time, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_amount, numericality: { only_integer: true }
  validates :turn_number, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
