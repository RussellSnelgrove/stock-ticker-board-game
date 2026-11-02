# typed: strict
# frozen_string_literal: true

class Game < ApplicationRecord
  extend T::Sig

  ROLLS_PER_TURN = 2
  DURATION_PRESETS = T.let([ 15, 30, 60, 90 ].freeze, T::Array[Integer])

  belongs_to :host, class_name: "User"
  # The player whose turn it is. Stored rather than computed from current_turn so that
  # joins, drops, and rejoins never change whose turn it is mid-turn.
  belongs_to :active_player, class_name: "Player", optional: true
  has_many :game_stocks, dependent: :destroy
  has_many :players, dependent: :destroy
  has_many :dice_rolls, dependent: :destroy
  has_many :messages, dependent: :destroy

  enum :status, {
    waiting: "waiting",
    in_progress: "in_progress",
    paused: "paused",
    completed: "completed"
  }, validate: true

  scope :listed, -> { where(status: [ :waiting, :in_progress ]) }

  validates :name, presence: true
  validates :invite_code, presence: true, uniqueness: true, length: { is: 6 }
  validates :duration, inclusion: { in: DURATION_PRESETS }
  validates :current_turn, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rolls_remaining_this_turn, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: ROLLS_PER_TURN
  }

  before_validation :generate_invite_code, on: :create
  after_commit :expire_listing_cache, if: :listing_changed?

  LISTING_CACHE_KEY = "games/listed"

  # IDs of games shown in the lobby, newest first. Expired whenever a game is created,
  # changes status, or gains or loses a player.
  sig { returns(T::Array[Integer]) }
  def self.listed_ids
    Rails.cache.fetch(LISTING_CACHE_KEY) { listed.order(created_at: :desc).ids }
  end

  sig { void }
  def self.expire_listing_cache
    Rails.cache.delete(LISTING_CACHE_KEY)
  end

  # Transitions ---------------------------------------------------------------

  sig { void }
  def start!
    raise GameRuleError, "Game must be in waiting status to start" unless waiting?

    now = Time.current
    update!(
      status: :in_progress,
      starts_at: now,
      ends_at: now + duration.minutes,
      active_player: players.active.order(:turn_position).first,
      rolls_remaining_this_turn: ROLLS_PER_TURN
    )
  end

  sig { void }
  def pause!
    raise GameRuleError, "Game must be in progress to pause" unless in_progress?
    raise GameRuleError, "Only solo games can be paused" unless solo?

    remaining = T.must(ends_at) - Time.current
    update!(status: :paused, remaining_time: remaining.to_i)
  end

  sig { void }
  def resume!
    raise GameRuleError, "Game must be paused to resume" unless paused?

    update!(status: :in_progress, ends_at: Time.current + T.must(remaining_time), remaining_time: nil)
  end

  sig { void }
  def complete!
    raise GameRuleError, "Game must be in progress to complete" unless in_progress?

    update!(status: :completed)
  end

  # Ends the active player's turn and passes play to the next active player in turn order.
  sig { void }
  def advance_turn!
    update!(
      active_player: next_active_player,
      current_turn: current_turn + 1,
      rolls_remaining_this_turn: ROLLS_PER_TURN
    )
  end

  # Gives the turn to someone if nobody active holds it, e.g. after every player left
  # and one rejoined.
  sig { void }
  def assign_turn_if_vacant!
    return unless in_progress?
    return if active_player&.active?

    update!(active_player: next_active_player, rolls_remaining_this_turn: ROLLS_PER_TURN)
  end

  # Queries -------------------------------------------------------------------

  sig { returns(T::Boolean) }
  def solo?
    players.count == 1
  end

  # True while players may roll and trade.
  sig { returns(T::Boolean) }
  def clock_running?
    in_progress? && ends_at.present? && T.must(ends_at) > Time.current
  end

  sig { returns(T::Boolean) }
  def trading_open?
    clock_running? && rolls_remaining_this_turn.zero?
  end

  sig { returns(T.nilable(Integer)) }
  def seconds_remaining
    return remaining_time if paused?
    return nil unless in_progress? && ends_at

    [ (T.must(ends_at) - Time.current).to_i, 0 ].max
  end

  sig { returns(T.nilable(Player)) }
  def next_active_player
    position = active_player&.turn_position || -1
    candidates = players.active.order(:turn_position)
    candidates.where("turn_position > ?", position).first || candidates.first
  end

  private

  sig { returns(T::Boolean) }
  def listing_changed?
    previously_new_record? || saved_change_to_status? || destroyed?
  end

  sig { void }
  def expire_listing_cache
    Game.expire_listing_cache
  end

  sig { void }
  def generate_invite_code
    return if invite_code.present?

    loop do
      self.invite_code = SecureRandom.alphanumeric(6).upcase
      break unless Game.exists?(invite_code: invite_code)
    end
  end
end
