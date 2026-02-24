# frozen_string_literal: true

class GameStock < ApplicationRecord
  PRICE_FLOOR = 0     # cents ($0.00)
  PRICE_CEILING = 200  # cents ($2.00)

  belongs_to :game
  belongs_to :stock
  has_many :holdings, dependent: :destroy
  has_many :game_transactions, dependent: :destroy

  validates :current_price, presence: true,
    numericality: { greater_than_or_equal_to: PRICE_FLOOR, less_than_or_equal_to: PRICE_CEILING }

  delegate :name, :symbol, :color, to: :stock

  def price_dollars
    current_price / 100.0
  end

  def lot_cost
    (500 * current_price) / 100
  end
end
