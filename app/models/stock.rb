# typed: strict
# frozen_string_literal: true

class Stock < ApplicationRecord
  extend T::Sig

  NAMES = %w[Grain Industrial Bonds Oil Silver Gold].freeze
  SYMBOLS = T.let(
    { "Grain" => "GRN", "Industrial" => "IND", "Bonds" => "BNDS", "Oil" => "OIL", "Silver" => "SLVR", "Gold" => "GOLD" }.freeze,
    T::Hash[String, String]
  )

  has_many :game_stocks, dependent: :destroy

  validates :name, presence: true, inclusion: { in: NAMES }

  scope :in_board_order, -> { in_order_of(:name, NAMES) }

  sig { returns(String) }
  def symbol
    SYMBOLS.fetch(name)
  end
end
