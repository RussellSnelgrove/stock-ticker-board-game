# frozen_string_literal: true

class User < ApplicationRecord
  has_many :hosted_games, class_name: "Game", foreign_key: :host_id, dependent: :nullify, inverse_of: :host
  has_many :players, dependent: :destroy
  has_many :games, through: :players
  has_many :messages, dependent: :destroy

  validates :display_name, presence: true, length: { maximum: 20 }
end
