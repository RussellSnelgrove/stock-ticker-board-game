# typed: false
# frozen_string_literal: true

module Types
  class PlayerStatusType < Types::BaseEnum
    value "ACTIVE", value: "active"
    value "DROPPED", value: "dropped"
  end
end
