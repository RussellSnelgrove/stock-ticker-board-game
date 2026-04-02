# typed: strict
# frozen_string_literal: true

class Player < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :game

  enum :status, {
    active: "active",
    dropped: "dropped"
  }, validate: true

  validates :cash, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :turn_position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
