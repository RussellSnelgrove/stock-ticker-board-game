# typed: false
# frozen_string_literal: true

module Subscriptions
  class GameEnded < BaseSubscription
    description "Fired when the game clock expires. Includes final rankings."

    field :game, Types::GameType, null: false
  end
end
