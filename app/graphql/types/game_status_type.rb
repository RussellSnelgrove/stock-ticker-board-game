# typed: false
# frozen_string_literal: true

module Types
  class GameStatusType < Types::BaseEnum
    value "WAITING", value: "waiting"
    value "IN_PROGRESS", value: "in_progress"
    value "PAUSED", value: "paused"
    value "COMPLETED", value: "completed"
  end
end
