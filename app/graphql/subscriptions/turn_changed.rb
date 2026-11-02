# typed: false
# frozen_string_literal: true

module Subscriptions
  class TurnChanged < BaseSubscription
    description "Fired when play passes to another player."

    field :game, Types::GameType, null: false
    field :active_player, Types::PlayerType, null: true
  end
end
