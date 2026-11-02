# typed: false
# frozen_string_literal: true

module Subscriptions
  class MessageReceived < BaseSubscription
    description "Fired when someone posts a chat message."

    field :message, Types::MessageType, null: false
  end
end
