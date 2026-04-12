# typed: strict
# frozen_string_literal: true

class Message < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :game

  validates :body, presence: true, length: { maximum: 200 }
end
