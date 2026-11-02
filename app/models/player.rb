# typed: strict
# frozen_string_literal: true

class Player < ApplicationRecord
  extend T::Sig

  STARTING_CASH = 500_000

  belongs_to :user
  belongs_to :game, touch: true

  has_many :game_transactions, dependent: :destroy
  has_many :dice_rolls, dependent: :destroy
  has_many :holdings, dependent: :destroy

  enum :status, {
    active: "active",
    dropped: "dropped"
  }, validate: true

  validates :cash, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :turn_position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # The lobby shows player counts, so joins and drops expire the listing.
  after_commit :expire_game_listing, if: :joined_or_left?

  sig { returns(Integer) }
  def portfolio_value
    holdings.includes(:game_stock).sum(&:value)
  end

  # Cash plus the current market value of all holdings, in cents.
  sig { returns(Integer) }
  def current_net_worth
    cash + portfolio_value
  end

  private

  sig { returns(T::Boolean) }
  def joined_or_left?
    previously_new_record? || saved_change_to_status? || destroyed?
  end

  sig { void }
  def expire_game_listing
    Game.expire_listing_cache
  end
end
