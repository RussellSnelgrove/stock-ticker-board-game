# typed: strict
# frozen_string_literal: true

class Stock < ApplicationRecord
  extend T::Sig

  NAMES = %w[Grain Industrial Bonds Oil Silver Gold].freeze

  has_many :game_stocks, dependent: :destroy

  validates :name, presence: true, inclusion: { in: NAMES }
end
