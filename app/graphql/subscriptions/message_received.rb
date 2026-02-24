# frozen_string_literal: true

module Subscriptions
  class MessageReceived < GraphQL::Schema::Subscription
    argument :game_id, ID, required: true

    field :message, Types::MessageType, null: false

    def authorized?(game_id:)
      game = Game.find_by(id: game_id)
      return false unless game
      game.players.exists?(user: context[:current_user])
    end

    def update
      object
    end
  end
end
