# typed: strict
# frozen_string_literal: true

class GameStock < ApplicationRecord
  extend T::Sig

  STARTING_PRICE = 100
  SPLIT_PRICE = 200
  DIVIDEND_MINIMUM_PRICE = 100

  belongs_to :game, touch: true
  belongs_to :stock

  has_many :game_transactions, dependent: :destroy
  has_many :holdings, dependent: :destroy

  validates :current_price, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: SPLIT_PRICE
  }
end
