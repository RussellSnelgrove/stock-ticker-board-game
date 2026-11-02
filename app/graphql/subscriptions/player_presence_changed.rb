# typed: false
# frozen_string_literal: true

module Subscriptions
  class PlayerPresenceChanged < BaseSubscription
    description "Fired when a player joins, leaves, rejoins, connects, or disconnects."

    field :player, Types::PlayerType, null: false
  end
end
