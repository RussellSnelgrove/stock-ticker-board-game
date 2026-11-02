# typed: strict
# frozen_string_literal: true

class Holding < ApplicationRecord
  extend T::Sig

  LOT_SIZE = 500

  belongs_to :player, touch: true
  belongs_to :game_stock

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :game_stock_id, uniqueness: { scope: :player_id }
  validate :quantity_is_whole_lots

  sig { returns(Integer) }
  def value
    quantity * T.must(game_stock).current_price
  end

  private

  sig { void }
  def quantity_is_whole_lots
    return if quantity.nil? || (quantity % LOT_SIZE).zero?

    errors.add(:quantity, "must be a multiple of #{LOT_SIZE}")
  end
end
