# frozen_string_literal: true

class DiceRollingService
  STARTING_PRICE = 100 # cents ($1.00)
  PRICE_CEILING = 200  # cents ($2.00)
  DIVIDEND_THRESHOLD = 100 # cents ($1.00)

  Result = Struct.new(:dice_roll, :events, keyword_init: true)

  def initialize(game:, player:)
    @game = game
    @player = player
  end

  def roll!
    stock = Stock.order("RANDOM()").first
    direction = DiceRoll::DIRECTIONS.sample
    amount = DiceRoll::AMOUNTS.sample
    game_stock = @game.game_stocks.find_by!(stock: stock)

    events = []

    dice_roll = DiceRoll.create!(
      game: @game,
      player: @player,
      stock: stock,
      turn_number: @game.current_turn,
      direction: direction,
      amount: amount
    )

    case direction
    when "up"
      events.concat(apply_up(game_stock, amount))
    when "down"
      events.concat(apply_down(game_stock, amount))
    when "dividend"
      events.concat(apply_dividend(game_stock, amount))
    end

    Result.new(dice_roll: dice_roll, events: events)
  end

  private

  def apply_up(game_stock, amount)
    events = []
    new_price = game_stock.current_price + amount

    if new_price >= PRICE_CEILING
      # Stock split: cap at ceiling, double shares, reset to $1.00
      holders = Holding.where(game_stock: game_stock).where("quantity > 0")
      holders.each do |holding|
        old_qty = holding.quantity
        holding.update!(quantity: old_qty * 2)
        GameTransaction.create!(
          player: holding.player,
          game_stock: game_stock,
          transaction_type: "split",
          quantity: old_qty,
          price_at_time: PRICE_CEILING,
          total_amount: 0,
          turn_number: @game.current_turn
        )
      end
      game_stock.update!(current_price: STARTING_PRICE)
      events << { type: "split", stock: game_stock.symbol, message: "#{game_stock.name} hits $2.00 — STOCK SPLIT! Shares doubled, price reset to $1.00" }
    else
      game_stock.update!(current_price: new_price)
      events << { type: "up", stock: game_stock.symbol, message: "#{game_stock.name} rises $#{format('%.2f', amount / 100.0)} to $#{format('%.2f', new_price / 100.0)}" }
    end

    events
  end

  def apply_down(game_stock, amount)
    events = []
    new_price = game_stock.current_price - amount

    if new_price <= 0
      # Worthless: wipe all shares, reset to $1.00
      holders = Holding.where(game_stock: game_stock).where("quantity > 0")
      holders.each do |holding|
        GameTransaction.create!(
          player: holding.player,
          game_stock: game_stock,
          transaction_type: "worthless_reset",
          quantity: holding.quantity,
          price_at_time: 0,
          total_amount: 0,
          turn_number: @game.current_turn
        )
        holding.update!(quantity: 0)
      end
      game_stock.update!(current_price: STARTING_PRICE)
      events << { type: "crash", stock: game_stock.symbol, message: "CRASH! #{game_stock.name} drops to $0 — shares wiped, price reset to $1.00" }
    else
      game_stock.update!(current_price: new_price)
      events << { type: "down", stock: game_stock.symbol, message: "#{game_stock.name} falls $#{format('%.2f', amount / 100.0)} to $#{format('%.2f', new_price / 100.0)}" }
    end

    events
  end

  def apply_dividend(game_stock, amount)
    events = []

    if game_stock.current_price < DIVIDEND_THRESHOLD
      events << { type: "dividend", stock: game_stock.symbol, message: "#{game_stock.name} dividend rolled but stock is below $1.00 — no effect" }
      return events
    end

    # Dividend rate: amount in cents maps to percentage (5 -> 5%, 10 -> 10%, 20 -> 20%)
    rate = amount.to_f / 100.0
    holders = Holding.where(game_stock: game_stock).where("quantity > 0").includes(:player)

    holders.each do |holding|
      payout = (holding.quantity * game_stock.current_price * rate / 100.0).round
      next if payout <= 0

      holding.player.update!(cash: holding.player.cash + payout)
      GameTransaction.create!(
        player: holding.player,
        game_stock: game_stock,
        transaction_type: "dividend",
        quantity: holding.quantity,
        price_at_time: game_stock.current_price,
        total_amount: payout,
        turn_number: @game.current_turn
      )
      events << { type: "dividend", stock: game_stock.symbol, message: "#{holding.player.user.display_name} receives $#{payout} dividend from #{game_stock.name}" }
    end

    if holders.empty? || events.select { |e| e[:message].include?("receives") }.empty?
      events << { type: "dividend", stock: game_stock.symbol, message: "#{game_stock.name} pays #{amount}% dividend — no holders" }
    end

    events
  end
end
