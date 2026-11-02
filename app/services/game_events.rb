# typed: strict
# frozen_string_literal: true

# Broadcasts game events to GraphQL subscribers. Every subscription takes a gameId
# argument; triggers pass it as a String so the topic matches what clients send.
module GameEvents
  extend T::Sig

  class << self
    extend T::Sig

    sig { params(game: Game).void }
    def game_started(game)
      trigger(:game_started, game, { game: game })
      turn_changed(game)
    end

    sig { params(game: Game, result: RollResult).void }
    def dice_rolled(game, result)
      trigger(:dice_rolled, game, { roll: result.to_event_payload })
      trigger(:game_stock_price_updated, game, { game_stock: result.game_stock, previous_price: result.previous_price })
      leaderboard_updated(game)
    end

    sig { params(game: Game, transaction: T.nilable(GameTransaction)).void }
    def leaderboard_updated(game, transaction: nil)
      trigger(:leaderboard_updated, game, { players: Leaderboard.ranked_players(game), transaction: transaction })
    end

    sig { params(game: Game).void }
    def turn_changed(game)
      trigger(:turn_changed, game, { game: game, active_player: game.active_player })
    end

    sig { params(game: Game, player: Player).void }
    def presence_changed(game, player)
      trigger(:player_presence_changed, game, { player: player })
    end

    sig { params(game: Game).void }
    def game_ended(game)
      trigger(:game_ended, game, { game: game })
    end

    sig { params(game: Game, message: Message).void }
    def message_received(game, message)
      trigger(:message_received, game, { message: message })
    end

    private

    sig { params(event: Symbol, game: Game, payload: T::Hash[Symbol, T.untyped]).void }
    def trigger(event, game, payload)
      StockTickerSchema.subscriptions.trigger(event, { game_id: game.id.to_s }, payload)
    end
  end
end
