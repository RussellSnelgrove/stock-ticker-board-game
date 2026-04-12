# typed: strict
# frozen_string_literal: true

class GameStock < ApplicationRecord
  extend T::Sig

  belongs_to :game
  belongs_to :stock

  has_many :game_transactions, dependent: :destroy

  validates :current_price, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 200
  }
end
