# frozen_string_literal: true

class GameClockExpiryJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = Game.find_by(id: game_id)
    return unless game&.in_progress?
    return if game.ends_at && game.ends_at > Time.current

    Game.transaction do
      game.update!(status: "completed")

      rankings = game.players.includes(holdings: :game_stock).map do |player|
        { player_id: player.id, display_name: player.user.display_name, net_worth: player.net_worth }
      end.sort_by { |r| -r[:net_worth] }

      StockTickerSchema.subscriptions.trigger(
        :game_ended,
        { game_id: game.id },
        { game: game, rankings: rankings }
      )
    end
  end
end
