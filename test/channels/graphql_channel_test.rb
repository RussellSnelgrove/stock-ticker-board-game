# typed: true
# frozen_string_literal: true

require "test_helper"

# Exercises the real delivery path: a client subscribes through GraphqlChannel, a game
# event is triggered, graphql-ruby broadcasts the serialized payload, and the channel
# re-runs the subscription query and sends the result to that client's stream.
class GraphqlChannelTest < ActionCable::Channel::TestCase
  tests GraphqlChannel

  setup do
    @game = games(:active_game)
    stub_connection current_user: users(:one)
    subscribe
  end

  def subscribe_to(query)
    perform :execute, "query" => query
    subscription_stream = subscription.streams.find { |s| s.start_with?("graphql-subscription:") }
    assert subscription_stream, "expected a subscription stream"
    subscription_stream.delete_prefix("graphql-subscription:")
  end

  # Replays what the event stream's listener does when a broadcast arrives.
  def deliver(field_name, subscription_id)
    event_stream = subscription.streams.find { |s| s.start_with?("graphql-event::#{field_name}:") }
    assert event_stream, "expected an event stream for #{field_name}"
    message = broadcasts(event_stream).last
    assert message, "expected a broadcast on #{event_stream}"

    object = GraphQL::Subscriptions::Serialize.load(JSON.parse(message))
    event = GraphQL::Subscriptions::Event.new(
      name: field_name,
      arguments: { "gameId" => @game.id.to_s },
      field: StockTickerSchema.subscription.get_field(field_name),
      context: GraphQL::Query.new(StockTickerSchema, "{ __typename }", validate: false).context
    )
    StockTickerSchema.subscriptions.execute(subscription_id, event, object)
    JSON.parse(broadcasts("graphql-subscription:#{subscription_id}").last)
  end

  test "dice rolls reach subscribers with the roll result" do
    sid = subscribe_to(<<~GQL)
      subscription { diceRolled(gameId: "#{@game.id}") { roll { outcome newPrice diceRoll { amount stockRolled { name } } } } }
    GQL

    result = DiceRollingService.new(game: @game, player: players(:player_two))
      .roll!(DiceRollingService::Dice.new(stock_name: "Oil", direction: "up", amount: 10))
    GameEvents.dice_rolled(@game, result)

    payload = deliver("diceRolled", sid)
    assert_equal(
      { "outcome" => "UP", "newPrice" => 110, "diceRoll" => { "amount" => 10, "stockRolled" => { "name" => "Oil" } } },
      payload.dig("result", "data", "diceRolled", "roll")
    )
  end

  test "chat messages reach subscribers" do
    sid = subscribe_to(<<~GQL)
      subscription { messageReceived(gameId: "#{@game.id}") { message { body user { displayName } } } }
    GQL

    message = @game.messages.create!(user: users(:two), body: "hello 👋")
    GameEvents.message_received(@game, message)

    payload = deliver("messageReceived", sid)
    assert_equal({ "body" => "hello 👋", "user" => { "displayName" => "Bob" } },
      payload.dig("result", "data", "messageReceived", "message"))
  end

  test "leaderboard updates list players by current net worth" do
    sid = subscribe_to(<<~GQL)
      subscription { leaderboardUpdated(gameId: "#{@game.id}") { players { user { displayName } currentNetWorth } } }
    GQL

    GameEvents.leaderboard_updated(@game)

    players = deliver("leaderboardUpdated", sid).dig("result", "data", "leaderboardUpdated", "players")
    assert_equal [ [ "Alice", 550_000 ], [ "Bob", 460_000 ], [ "Carol", 120_000 ] ],
      players.map { |p| [ p.dig("user", "displayName"), p["currentNetWorth"] ] }
  end

  test "every game event broadcasts on its own topic" do
    {
      "gameStarted" => -> { GameEvents.game_started(@game) },
      "turnChanged" => -> { GameEvents.turn_changed(@game) },
      "playerPresenceChanged" => -> { GameEvents.presence_changed(@game, players(:player_one)) },
      "gameEnded" => -> { GameEvents.game_ended(@game) }
    }.each do |field_name, fire|
      stream = "graphql-event::#{field_name}:gameId:#{@game.id}"
      assert_broadcasts(stream, 1) { fire.call }
    end
  end

  test "subscribing requires an existing game" do
    perform :execute, "query" => 'subscription { gameEnded(gameId: "0") { game { id } } }'
    assert_equal [ "Game not found" ], transmissions.last.dig("result", "errors").map { |e| e["message"] }
  end
end
