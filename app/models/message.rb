# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :user
  belongs_to :game

  validates :body, presence: true, length: { maximum: 200 }

  scope :recent_first, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
end
