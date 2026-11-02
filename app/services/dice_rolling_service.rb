# typed: strict
# frozen_string_literal: true

# Rolls the three dice for the active player and moves the market.
class DiceRollingService
  extend T::Sig

  # up/down: price moved. split: price reached $2.00, holders' shares doubled, price reset.
  # worthless: price reached $0.00, holders' shares removed, price reset.
  # dividend: holders paid. dividend_skipped: price below $1.00, nothing paid.
  OUTCOMES = T.let(%w[up down split worthless dividend dividend_skipped].freeze, T::Array[String])
  DIRECTIONS = T.let(%w[up down dividend].freeze, T::Array[String])

  class Dice < T::Struct
    const :stock_name, String
    const :direction, String
    const :amount, Integer
  end

  # Each die is uniformly weighted.
  sig { params(random: Random).returns(Dice) }
  def self.throw_dice(random = Random.new)
    Dice.new(
      stock_name: T.must(Stock::NAMES.sample(random: random)),
      direction: T.must(DIRECTIONS.sample(random: random)),
      amount: T.must(DiceRoll::VALID_AMOUNTS.sample(random: random))
    )
  end

  sig { params(game: Game, player: Player, random: Random).void }
  def initialize(game:, player:, random: Random.new)
    @game = game
    @player = player
    @random = random
  end

  sig { params(dice: T.nilable(Dice)).returns(RollResult) }
  def roll!(dice = nil)
    @game.with_lock do
      check_can_roll!
      thrown = dice || self.class.throw_dice(@random)

      game_stock = @game.game_stocks.joins(:stock).find_by!(stocks: { name: thrown.stock_name })
      previous_price = game_stock.current_price
      outcome = move_market(game_stock, thrown)

      dice_roll = @game.dice_rolls.create!(
        player: @player,
        turn_number: @game.current_turn,
        stock_rolled: game_stock.stock,
        direction: thrown.direction,
        amount: thrown.amount
      )
      @game.update!(rolls_remaining_this_turn: @game.rolls_remaining_this_turn - 1)

      RollResult.new(
        dice_roll: dice_roll,
        game_stock: game_stock,
        outcome: outcome,
        previous_price: previous_price,
        new_price: game_stock.current_price,
        rolls_remaining: @game.rolls_remaining_this_turn
      )
    end
  end

  private

  sig { void }
  def check_can_roll!
    raise GameRuleError, "The game is not running" unless @game.clock_running?
    raise GameRuleError, "It is not your turn" unless @game.active_player_id == @player.id
    raise GameRuleError, "You have no rolls left this turn" if @game.rolls_remaining_this_turn.zero?
  end

  sig { params(game_stock: GameStock, dice: Dice).returns(String) }
  def move_market(game_stock, dice)
    price = game_stock.current_price

    case dice.direction
    when "up"
      return split!(game_stock) if price + dice.amount >= GameStock::SPLIT_PRICE

      game_stock.update!(current_price: price + dice.amount)
      "up"
    when "down"
      return worthless!(game_stock) if price - dice.amount <= 0

      game_stock.update!(current_price: price - dice.amount)
      "down"
    else
      return "dividend_skipped" if price < GameStock::DIVIDEND_MINIMUM_PRICE

      pay_dividend!(game_stock, dice.amount)
      "dividend"
    end
  end

  sig { params(game_stock: GameStock).returns(String) }
  def split!(game_stock)
    each_holding(game_stock) do |holding|
      record!(holding, :stock_split, quantity: holding.quantity, price: GameStock::SPLIT_PRICE, total: 0)
      holding.update!(quantity: holding.quantity * 2)
    end
    game_stock.update!(current_price: GameStock::STARTING_PRICE)
    "split"
  end

  sig { params(game_stock: GameStock).returns(String) }
  def worthless!(game_stock)
    each_holding(game_stock) do |holding|
      record!(holding, :worthless_reset, quantity: holding.quantity, price: 0, total: 0)
      holding.destroy!
    end
    game_stock.update!(current_price: GameStock::STARTING_PRICE)
    "worthless"
  end

  # The dividend rate equals the amount die: 5, 10, or 20 percent of the price per share.
  sig { params(game_stock: GameStock, percent: Integer).void }
  def pay_dividend!(game_stock, percent)
    each_holding(game_stock) do |holding|
      payout = game_stock.current_price * holding.quantity * percent / 100
      holder = T.must(holding.player)
      holder.update!(cash: holder.cash + payout)
      record!(holding, :dividend, quantity: holding.quantity, price: game_stock.current_price, total: payout)
    end
  end

  sig { params(game_stock: GameStock, block: T.proc.params(holding: Holding).void).void }
  def each_holding(game_stock, &block)
    game_stock.holdings.where("quantity > 0").includes(:player).order(:id).each(&block)
  end

  sig { params(holding: Holding, type: Symbol, quantity: Integer, price: Integer, total: Integer).void }
  def record!(holding, type, quantity:, price:, total:)
    GameTransaction.create!(
      player: holding.player,
      game_stock: holding.game_stock,
      transaction_type: type,
      quantity: quantity,
      price_at_time: price,
      total_amount: total,
      turn_number: @game.current_turn
    )
  end
end
