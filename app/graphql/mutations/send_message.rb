# frozen_string_literal: true

module Mutations
  class SendMessage < BaseMutation
    argument :game_id, ID, required: true
    argument :body, String, required: true

    field :message, Types::MessageType, null: true
    field :errors, [String], null: false

    def resolve(game_id:, body:)
      user = context[:current_user]
      return { message: nil, errors: ["You must be logged in"] } unless user

      game = Game.find_by(id: game_id)
      return { message: nil, errors: ["Game not found"] } unless game

      player = game.players.find_by(user: user)
      return { message: nil, errors: ["You are not in this game"] } unless player

      message = game.messages.create(user: user, body: body)

      if message.persisted?
        StockTickerSchema.subscriptions.trigger(:message_received, { game_id: game.id }, { message: message })
        { message: message, errors: [] }
      else
        { message: nil, errors: message.errors.full_messages }
      end
    end
  end
end
