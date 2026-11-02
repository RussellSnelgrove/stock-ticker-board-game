# typed: true
# frozen_string_literal: true

require "test_helper"

class Mutations::SendMessageTest < ActiveSupport::TestCase
  MUTATION = <<~GQL
    mutation($gameId: ID!, $body: String!) {
      sendMessage(input: { gameId: $gameId, body: $body }) {
        message { body user { displayName } }
        errors
      }
    }
  GQL

  def send_as(user, body)
    StockTickerSchema.execute(MUTATION, variables: { gameId: games(:active_game).id, body: body }, context: { current_user: user })
      .to_h.dig("data", "sendMessage")
  end

  test "a player posts a message, emoji intact" do
    data = send_as(users(:one), "  Buying gold 🚀📈  ")

    assert_empty data["errors"]
    assert_equal "Buying gold 🚀📈", data.dig("message", "body")
    assert_equal "Buying gold 🚀📈", T.must(Message.last).reload.body
  end

  test "messages over 200 characters are rejected" do
    data = send_as(users(:one), "x" * 201)
    assert_nil data["message"]
    assert_equal [ "Body is too long (maximum is 200 characters)" ], data["errors"]
  end

  test "blank messages are rejected" do
    assert_equal [ "Body can't be blank" ], send_as(users(:one), "   ")["errors"]
  end

  test "users outside the game cannot post" do
    assert_equal [ "You are not in this game" ], send_as(User.create!(display_name: "Eve"), "hi")["errors"]
  end
end
