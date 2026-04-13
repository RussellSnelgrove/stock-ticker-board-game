# typed: strict
# frozen_string_literal: true

class User < ApplicationRecord
  extend T::Sig

  has_many :players, dependent: :destroy
  has_many :games, through: :players
  has_many :messages, dependent: :destroy

  validates :display_name, presence: true
end
