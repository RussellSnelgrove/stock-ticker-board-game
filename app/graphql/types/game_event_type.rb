# frozen_string_literal: true

module Types
  class GameEventType < Types::BaseObject
    field :event_type, String, null: false
    field :stock_symbol, String, null: true
    field :message, String, null: false
  end
end
