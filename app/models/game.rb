# frozen_string_literal: true

class Game < ApplicationRecord
  STATUSES = %w[waiting in_progress paused completed].freeze
  STARTING_PRICE = 100 # cents ($1.00)

  belongs_to :host, class_name: "User"
  has_many :players, dependent: :destroy
  has_many :game_stocks, dependent: :destroy
  has_many :dice_rolls, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :name, presence: true
  validates :invite_code, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :duration, presence: true, numericality: { greater_than: 0 }

  before_validation :generate_invite_code, on: :create
  after_create :initialize_game_stocks

  scope :joinable, -> { where(status: "waiting") }
  scope :active, -> { where(status: %w[waiting in_progress]) }

  def waiting?     = status == "waiting"
  def in_progress? = status == "in_progress"
  def paused?      = status == "paused"
  def completed?   = status == "completed"

  def active_player
    players.active.order(:turn_position).offset(current_turn % players.active.count).first
  end

  def rolls_completed_this_turn
    return 0 unless active_player
    dice_rolls.where(player: active_player, turn_number: current_turn).count
  end

  def rolls_remaining_this_turn
    [Mutations::RollDice::ROLLS_PER_TURN - rolls_completed_this_turn, 0].max
  end

  def time_remaining
    return remaining_time if paused?
    return 0 if completed? || ends_at.nil?

    [(ends_at - Time.current).to_i, 0].max
  end

  private

  def generate_invite_code
    self.invite_code ||= SecureRandom.alphanumeric(6).upcase
  end

  def initialize_game_stocks
    Stock.find_each do |stock|
      game_stocks.create!(stock: stock, current_price: STARTING_PRICE)
    end
  end
end
