# typed: false
# frozen_string_literal: true

module Subscriptions
  class DiceRolled < BaseSubscription
    description "Fired after every roll with the dice values and what they did to the market."

    field :roll, Types::RollResultType, null: false
  end
end
