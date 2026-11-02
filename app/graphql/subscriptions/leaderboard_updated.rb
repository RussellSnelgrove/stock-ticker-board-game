# typed: false
# frozen_string_literal: true

module Subscriptions
  class LeaderboardUpdated < BaseSubscription
    description "Fired after any roll or trade that can change net worth. Players are ranked by current net worth."

    field :players, [ Types::PlayerType ], null: false
    field :transaction, Types::GameTransactionType, null: true, description: "The trade that caused this update, if any"
  end
end
