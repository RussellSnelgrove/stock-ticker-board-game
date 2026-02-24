# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_game, mutation: Mutations::CreateGame
    field :start_game, mutation: Mutations::StartGame
    field :join_game, mutation: Mutations::JoinGame
    field :leave_game, mutation: Mutations::LeaveGame
    field :pause_game, mutation: Mutations::PauseGame
    field :roll_dice, mutation: Mutations::RollDice
    field :buy_shares, mutation: Mutations::BuyShares
    field :sell_shares, mutation: Mutations::SellShares
    field :end_turn, mutation: Mutations::EndTurn
    field :send_message, mutation: Mutations::SendMessage
  end
end
