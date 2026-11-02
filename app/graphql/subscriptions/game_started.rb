# typed: false
# frozen_string_literal: true

module Subscriptions
  class GameStarted < BaseSubscription
    description "Fired when the host starts the game."

    field :game, Types::GameType, null: false
  end
end
