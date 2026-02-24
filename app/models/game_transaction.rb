# frozen_string_literal: true

class GameTransaction < ApplicationRecord
  TYPES = %w[buy sell dividend split worthless_reset].freeze

  belongs_to :player
  belongs_to :game_stock

  validates :transaction_type, presence: true, inclusion: { in: TYPES }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :price_at_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true
  validates :turn_number, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :for_game, ->(game) { joins(:game_stock).where(game_stocks: { game_id: game.id }) }
  scope :recent_first, -> { order(created_at: :desc) }
end
