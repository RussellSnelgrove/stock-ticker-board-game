# typed: strict
# frozen_string_literal: true

# What one roll of the three dice did to the market.
class RollResult < T::Struct
  extend T::Sig

  const :dice_roll, DiceRoll
  const :game_stock, GameStock
  # One of DiceRollingService::OUTCOMES.
  const :outcome, String
  const :previous_price, Integer
  const :new_price, Integer
  const :rolls_remaining, Integer

  # Subscription payloads must survive GraphQL::Subscriptions::Serialize, which handles
  # hashes and Active Record objects but not structs.
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def to_event_payload
    {
      dice_roll: dice_roll,
      game_stock: game_stock,
      outcome: outcome,
      previous_price: previous_price,
      new_price: new_price,
      rolls_remaining: rolls_remaining
    }
  end
end
