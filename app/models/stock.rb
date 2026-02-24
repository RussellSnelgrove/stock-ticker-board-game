# frozen_string_literal: true

class Stock < ApplicationRecord
  has_many :game_stocks, dependent: :destroy
  has_many :dice_rolls, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :symbol, presence: true, uniqueness: true
  validates :color, presence: true

  COMMODITIES = [
    { name: "Gold",       symbol: "GOLD", color: "#F59E0B" },
    { name: "Silver",     symbol: "SLVR", color: "#94A3B8" },
    { name: "Bonds",      symbol: "BNDS", color: "#3B82F6" },
    { name: "Grain",      symbol: "GRN",  color: "#D97706" },
    { name: "Industrial", symbol: "IND",  color: "#EF4444" },
    { name: "Oil",        symbol: "OIL",  color: "#10B981" }
  ].freeze
end
