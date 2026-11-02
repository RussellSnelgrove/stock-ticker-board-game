# typed: false
# frozen_string_literal: true

module Types
  class RollResultType < Types::BaseObject
    field :dice_roll, Types::DiceRollType, null: false
    field :game_stock, Types::GameStockType, null: false
    field :outcome, Types::RollOutcomeType, null: false
    field :previous_price, Integer, null: false, description: "Price in cents before the roll"
    field :new_price, Integer, null: false, description: "Price in cents after the roll"
    field :rolls_remaining, Integer, null: false
  end
end
