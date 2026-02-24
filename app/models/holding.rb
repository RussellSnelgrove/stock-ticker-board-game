# frozen_string_literal: true

class Holding < ApplicationRecord
  LOT_SIZE = 500

  belongs_to :player
  belongs_to :game_stock

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :game_stock_id, uniqueness: { scope: :player_id }

  def lots
    quantity / LOT_SIZE
  end

  def value
    quantity * game_stock.current_price / 100
  end
end
