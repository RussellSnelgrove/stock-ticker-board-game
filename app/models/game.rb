# typed: strict
# frozen_string_literal: true

class Game < ApplicationRecord
  extend T::Sig

  ROLLS_PER_TURN = 2
  DURATION_PRESETS = T.let([ 15, 30, 60, 90 ].freeze, T::Array[Integer])

  belongs_to :host, class_name: "User"
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

  # Transitions ---------------------------------------------------------------

  sig { void }
  def start!
    raise "Game must be in waiting status to start" unless waiting?

    now = Time.current
    update!(status: :in_progress, starts_at: now, ends_at: now + duration.minutes)
  end

  sig { void }
  def pause!
    raise "Game must be in progress to pause" unless in_progress?

    remaining = T.must(ends_at) - Time.current
    update!(status: :paused, remaining_time: remaining.to_i)
  end

  sig { void }
  def resume!
    raise "Game must be paused to resume" unless paused?

    update!(status: :in_progress, ends_at: Time.current + T.must(remaining_time), remaining_time: nil)
  end

  sig { void }
  def complete!
    raise "Game must be in progress to complete" unless in_progress?

    update!(status: :completed)
  end

  # Computed ------------------------------------------------------------------

  sig { returns(T.nilable(Player)) }
  def active_player
    return nil unless in_progress?

    count = active_player_count
    return nil if count.zero?

    players.active.order(:turn_position).offset(current_turn % count).first
  end

  private

  sig { returns(Integer) }
  def active_player_count
    players.active.count
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
