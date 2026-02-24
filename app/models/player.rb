# frozen_string_literal: true

class Player < ApplicationRecord
  STARTING_CASH = 5000
  STATUSES = %w[active dropped].freeze

  belongs_to :user
  belongs_to :game
  has_many :holdings, dependent: :destroy
  has_many :game_transactions, dependent: :destroy
  has_many :dice_rolls, dependent: :destroy

  validates :cash, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :turn_position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :game_id, message: "is already in this game" }

  scope :active, -> { where(status: "active") }
  scope :by_turn_order, -> { order(:turn_position) }

  def active? = status == "active"
  def dropped? = status == "dropped"

  def net_worth
    stock_value = holdings.includes(:game_stock).sum { |h| h.quantity * h.game_stock.current_price / 100 }
    cash + stock_value
  end

  def shares_of(game_stock)
    holdings.find_by(game_stock: game_stock)&.quantity || 0
  end
end
