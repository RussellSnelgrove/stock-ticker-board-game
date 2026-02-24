# frozen_string_literal: true

class DiceRoll < ApplicationRecord
  DIRECTIONS = %w[up down dividend].freeze
  AMOUNTS = [5, 10, 20].freeze # cents

  belongs_to :game
  belongs_to :player
  belongs_to :stock

  validates :turn_number, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  validates :amount, presence: true, inclusion: { in: AMOUNTS }
end
