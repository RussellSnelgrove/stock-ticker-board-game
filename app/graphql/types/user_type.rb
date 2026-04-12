# typed: false
# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :display_name, String, null: false
  end
end
