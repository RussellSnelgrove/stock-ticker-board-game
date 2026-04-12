# typed: false
# frozen_string_literal: true

module Types
  class MessageType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :body, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
