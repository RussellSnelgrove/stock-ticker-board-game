# typed: strict
# frozen_string_literal: true

class DiceRoll < ApplicationRecord
  extend T::Sig

  VALID_AMOUNTS = T.let([ 5, 10, 20 ].freeze, T::Array[Integer])

  belongs_to :game
  belongs_to :player
  belongs_to :stock_rolled, class_name: "Stock"

  enum :direction, {
    up: "up",
    down: "down",
    dividend: "dividend"
  }, validate: true

  validates :turn_number, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :amount, inclusion: { in: VALID_AMOUNTS }
end
