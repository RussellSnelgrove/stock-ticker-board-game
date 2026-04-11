# typed: strict
# frozen_string_literal: true

module Types
  class SubscriptionType < Types::BaseObject
    field :game_ended, subscription: Subscriptions::GameEnded,
      description: "Fired when a game's clock expires; includes final rankings"
  end
end
