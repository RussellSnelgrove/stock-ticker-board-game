# frozen_string_literal: true

module Types
  class SubscriptionType < Types::BaseObject
    field :game_started, subscription: Subscriptions::GameStarted
    field :game_stock_price_updated, subscription: Subscriptions::GameStockPriceUpdated
    field :dice_rolled, subscription: Subscriptions::DiceRolled
    field :turn_changed, subscription: Subscriptions::TurnChanged
    field :player_presence_changed, subscription: Subscriptions::PlayerPresenceChanged
    field :game_ended, subscription: Subscriptions::GameEnded
    field :message_received, subscription: Subscriptions::MessageReceived
  end
end
