# typed: false
# frozen_string_literal: true

module Types
  class TransactionTypeType < Types::BaseEnum
    value "BUY", value: "buy"
    value "SELL", value: "sell"
    value "DIVIDEND", value: "dividend"
    value "STOCK_SPLIT", value: "stock_split"
    value "WORTHLESS_RESET", value: "worthless_reset"
  end
end
