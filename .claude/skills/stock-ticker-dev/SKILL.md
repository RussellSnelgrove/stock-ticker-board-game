---
name: stock-ticker-dev
description: Full development guide for the Stock Ticker project — game rules, Rails/GraphQL patterns, and Docker dev workflow. Use when implementing game logic, writing GraphQL mutations/subscriptions, or running the dev environment.
allowed-tools: Read, Grep, Glob, Bash
---

# Stock Ticker — Project Dev Guide

## Game Rules & Mechanics

### Core Setup
- 6 commodities: **Grain, Industrial, Bonds, Oil, Silver, Gold**
- All stocks start at **$1.00** per game
- Players compete for highest net worth (cash + portfolio value) before the timer expires

### Turn Sequence
1. Roll dice (Roll 1) → market moves
2. Roll dice (Roll 2) → market moves
3. Trade window opens (buy/sell)
4. End turn → next player

### Dice System (3 dice, rolled twice per turn)
| Die | Determines | Values |
|-----|-----------|--------|
| Die 1 | Which stock | Grain, Industrial, Bonds, Oil, Silver, Gold |
| Die 2 | Direction | Up, Down, Dividend |
| Die 3 | Amount | $0.05, $0.10, $0.20 |

### Special Events
- **Stock Split** — stock hits $2.00 → all holders' shares double, price resets to $1.00
- **Worthless** — stock drops to $0.00 → all holders lose shares, price resets to $1.00
- **Dividend** — only pays out when stock price ≥ $1.00; payout = Die 3 % × current price × shares held
  - Dividends rolled for stocks below $1.00 have no effect

### Game Clock
- Host sets duration at creation (e.g., 30/60/90 min)
- `GameClockExpiryJob` fires when timer hits zero
- Trading freezes at expiry; highest net worth wins

---

## Project Structure

```
app/
├── models/          # Stock, GameStock, Game, Player, Holding, GameTransaction, DiceRoll, Message, User
├── services/        # DiceRollingService, TradingService
├── jobs/            # GameClockExpiryJob
├── controllers/     # GraphqlController, GamesController, SessionsController
├── channels/        # Action Cable (GraphQL subscription transport)
└── graphql/
    ├── types/       # GameType, GameStockType, PlayerType, HoldingType, etc.
    ├── mutations/   # BuyShares, SellShares, RollDice, etc.
    └── subscriptions/  # Price updates, chat, turn notifications
```

---

## Rails / GraphQL Patterns

### GraphQL Mutation pattern
```ruby
module Mutations
  class MyMutation < BaseMutation
    argument :game_id, ID, required: true

    field :game, Types::GameType, null: true
    field :errors, [String], null: false

    def resolve(game_id:)
      game = Game.find(game_id)
      # ... logic ...
      { game: game, errors: [] }
    rescue => e
      { game: nil, errors: [e.message] }
    end
  end
end
```

### GraphQL Subscription pattern
- Subscriptions go in `app/graphql/subscriptions/`
- Delivered via Action Cable
- Trigger with: `StockTickerSchema.subscriptions.trigger("event_name", {args}, object)`

### Service Objects
- `DiceRollingService` — handles dice roll logic, market movement, split/worthless/dividend events
- `TradingService` — handles buy/sell, validates trade window is open
- Keep business logic in services, not models or mutations

### Identity
- Session-based, no Devise; user picks a username
- Current user: `current_user` helper in controllers (via session)

---

## Dev Environment

### Starting the environment (Docker — primary)
```bash
colima start --cpu 4 --memory 6 --vm-type vz --vz-rosetta
docker-compose up --build
# First time only:
docker-compose exec app bin/docker-setup
```

### Common Docker commands
```bash
docker-compose exec app bin/rails console   # Rails console
docker-compose exec app bin/rails test      # Run tests
docker-compose logs -f app                  # Tail logs
docker-compose down                         # Stop
docker-compose down -v                      # Stop + wipe data
colima stop                                 # Stop the VM
```

### Local dev (no Docker)
```bash
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/opt/postgresql@16/bin:$PATH"
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

### Running tests
```bash
# Docker
docker-compose exec app bin/rails test
# Local
bundle exec rails test
```

---

## Contributing Workflow
1. Always branch off `develop`: `git checkout develop && git checkout -b feature/my-feature`
2. Keep commits focused; open PRs back to `develop`
3. `main` is the stable/production branch

---

## Key Files to Know
- `db/seeds.rb` — seeds the 6 default stock commodities
- `app/services/DiceRollingService` — core game engine logic
- `app/jobs/GameClockExpiryJob` — handles game expiry
- `docker-compose.yml` — app + PostgreSQL + Redis services
