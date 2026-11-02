# typed: false
# frozen_string_literal: true

module Types
  class RollOutcomeType < Types::BaseEnum
    description "What a roll did to the market"

    value "UP", value: "up"
    value "DOWN", value: "down"
    value "SPLIT", value: "split", description: "Price reached $2.00; holders' shares doubled and price reset to $1.00"
    value "WORTHLESS", value: "worthless", description: "Price reached $0.00; holders' shares removed and price reset to $1.00"
    value "DIVIDEND", value: "dividend"
    value "DIVIDEND_SKIPPED", value: "dividend_skipped", description: "Dividend rolled below $1.00; nothing paid"
  end
end
