# typed: strict
# frozen_string_literal: true

# Buys and sells shares for the active player during their trading phase.
class TradingService
  extend T::Sig

  sig { params(game: Game, player: Player).void }
  def initialize(game:, player:)
    @game = game
    @player = player
  end

  sig { params(game_stock_id: T.any(Integer, String), quantity: Integer).returns(GameTransaction) }
  def buy!(game_stock_id:, quantity:)
    trade(game_stock_id, quantity) do |game_stock, holding, amount|
      raise GameRuleError, "Not enough cash for that purchase" if amount > @player.cash

      @player.update!(cash: @player.cash - amount)
      holding.update!(quantity: holding.quantity + quantity)
      :buy
    end
  end

  sig { params(game_stock_id: T.any(Integer, String), quantity: Integer).returns(GameTransaction) }
  def sell!(game_stock_id:, quantity:)
    trade(game_stock_id, quantity) do |game_stock, holding, amount|
      raise GameRuleError, "You do not own that many shares" if quantity > holding.quantity

      @player.update!(cash: @player.cash + amount)
      remaining = holding.quantity - quantity
      remaining.zero? ? holding.destroy! : holding.update!(quantity: remaining)
      :sell
    end
  end

  private

  sig do
    params(
      game_stock_id: T.any(Integer, String),
      quantity: Integer,
      block: T.proc.params(game_stock: GameStock, holding: Holding, amount: Integer).returns(Symbol)
    ).returns(GameTransaction)
  end
  def trade(game_stock_id, quantity, &block)
    @game.with_lock do
      check_can_trade!
      unless quantity.positive? && (quantity % Holding::LOT_SIZE).zero?
        raise GameRuleError, "Shares trade in lots of #{Holding::LOT_SIZE}"
      end

      game_stock = @game.game_stocks.find_by(id: game_stock_id)
      raise GameRuleError, "That stock is not part of this game" unless game_stock

      @player.reload
      holding = @player.holdings.find_or_initialize_by(game_stock: game_stock)
      amount = game_stock.current_price * quantity
      type = block.call(game_stock, holding, amount)

      @player.game_transactions.create!(
        game_stock: game_stock,
        transaction_type: type,
        quantity: quantity,
        price_at_time: game_stock.current_price,
        total_amount: amount,
        turn_number: @game.current_turn
      )
    end
  end

  sig { void }
  def check_can_trade!
    raise GameRuleError, "The game is not running" unless @game.clock_running?
    raise GameRuleError, "It is not your turn" unless @game.active_player_id == @player.id
    raise GameRuleError, "Finish both rolls before trading" unless @game.rolls_remaining_this_turn.zero?
  end
end
