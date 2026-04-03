# typed: false
# frozen_string_literal: true

module Types
  class PlayerType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :cash, Integer, null: false,
      description: "Cash on hand in cents (500_000 = $5,000)"
    field :status, Types::PlayerStatusType, null: false
    field :turn_position, Integer, null: false
  end
end
