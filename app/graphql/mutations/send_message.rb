# typed: false
# frozen_string_literal: true

module Mutations
  class SendMessage < BaseMutation
    description "Post a chat message (up to 200 characters) to a game you are in."

    argument :game_id, ID, required: true
    argument :body, String, required: true

    field :message, Types::MessageType, null: true
    field :errors, [ String ], null: false

    def resolve(game_id:, body:)
      game = find_game!(game_id)
      find_player!(game)
      message = game.messages.new(user: current_user!, body: body.strip)
      return { message: nil, errors: message.errors.full_messages } unless message.save

      GameEvents.message_received(game, message)
      { message: message, errors: [] }
    rescue GameRuleError => e
      { message: nil, errors: [ e.message ] }
    end
  end
end
