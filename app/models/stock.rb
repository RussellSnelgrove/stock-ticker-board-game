# typed: strict
# frozen_string_literal: true

class Stock < ApplicationRecord
  NAMES = %w[Grain Industrial Bonds Oil Silver Gold].freeze

  validates :name, presence: true, inclusion: { in: NAMES }
end
