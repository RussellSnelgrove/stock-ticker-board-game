---
name: stock-ticker-dev
description: Full development guide for the Stock Ticker project — game rules, Rails/GraphQL patterns, data models, UI design system, and Docker dev workflow. Use when implementing game logic, writing GraphQL mutations/subscriptions, building UI, or running the dev environment.
allowed-tools: Read, Grep, Glob, Bash
---

# Stock Ticker — Project Dev Guide

## Game Rules & Mechanics

### Core Setup
- 6 commodities in fixed order: **Grain, Industrial, Bonds, Oil, Silver, Gold**
- All stocks start at **$1.00** per game (stored as integer cents: 100)
- Price range: $0.00–$2.00 (cents: 0–200)
- Players start with **$5,000 cash** (stored as integer cents: 500_000)
- Players compete for highest net worth (cash + portfolio value) before timer expires
- Shares bought/sold in lots of **500**; share supply is unlimited

### Turn Sequence
1. Roll dice (Roll 1 of 2) → market moves
2. Roll dice (Roll 2 of 2) → market moves
3. Trade window opens (active player may buy/sell multiple times)
4. End turn → next player

### Dice System (3 dice, rolled twice per turn — all uniformly weighted)
| Die | Determines | Values |
|-----|-----------|--------|
| Die 1 | Which stock | Grain, Industrial, Bonds, Oil, Silver, Gold (1/6 each) |
| Die 2 | Direction | Up, Down, Dividend (1/3 each) |
| Die 3 | Amount | $0.05, $0.10, $0.20 (1/3 each; stored as cents: 5, 10, 20) |

### Special Events
- **Stock Split** — stock reaches $2.00 → cap at $2.00, all holders' shares double, price resets to $1.00 (no carry-over of excess)
- **Worthless** — stock drops to $0.00 → all holders' shares wiped, price resets to $1.00; play continues
- **Dividend** — pays out only when stock price ≥ $1.00; payout = Die 3 % × current price × shares held (5%, 10%, or 20%); no effect below $1.00

### Game Clock & Duration
- Host selects duration at creation — **presets only**: 15, 30, 60, or 90 minutes; no free-form input
- `GameClockExpiryJob` fires at `ends_at` to freeze trading and compute final rankings
- **Tie-breaking**: equal net worth → rank by `turn_position` ascending (earlier joiner wins)
- **Solo games**: 1 player; host creates and starts alone; can pause/resume
- **Multiplayer**: no player limit; turn order = join order; mid-game joins appended to end of turn order

### Turn / Player Rules
- `ROLLS_PER_TURN = 2` — tracked via `rolls_remaining_this_turn` on `Game`
- Only the **active player** may roll or trade
- Trading only allowed after both rolls are complete
- A player may make multiple buy/sell transactions before calling `EndTurn`
- If the active player drops mid-turn, auto-roll remaining rolls via `DiceRollingService`, then advance; dropped players are skipped on subsequent turns
- Mid-game joins: $5,000 cash, 0 shares; must wait for their turn

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Ruby on Rails 8.1.2 |
| Ruby | 3.3.7 (pinned in `Dockerfile.dev` and `Gemfile`) |
| API | GraphQL (`graphql-ruby`) |
| Database | PostgreSQL (Yugabyte-compatible for production) |
| Caching/Real-time | Redis (cache store + Action Cable + GraphQL subscriptions) |
| Background Jobs | Active Job with `:async` adapter (no Solid Queue) |
| Identity | Session-based; user picks username; no Devise |
| JS | Vanilla JS + `fetch` + importmap (no framework) |
| Containerization | Colima + Docker CLI + Docker Compose |
| Types | Sorbet (`sorbet` + `tapioca` gems) |

**Key constraints:**
- Primary dev method is `docker-compose up` — do NOT assume local services
- Local dev (without Docker) must also work for developers who can't run containers
- Do NOT use rbenv or rvm — use chruby or Homebrew Ruby (`brew install ruby`)
- Importmap requires **bare specifiers**: `import GameClient from "game_client"` NOT `"./game_client"`. Pin each module in `config/importmap.rb`.
- Active Job adapter: `:async` in development (runs in-process, no separate worker)
- No Solid gems: `solid_cache`, `solid_queue`, `solid_cable` are removed

---

## Data Models

### Prices & Money (always stored as integer cents)
- Stock prices: 100 = $1.00; display via `(cents / 100.0).round(2)`
- Cash/net worth: 500_000 = $5,000; display with thousand separators, no decimals
- Dividend amounts stored as cents: 5 = $0.05, 10 = $0.10, 20 = $0.20

### Models
- **User** — `display_name` only; no authentication
- **Stock** — static lookup; 6 records seeded in order: Grain, Industrial, Bonds, Oil, Silver, Gold
- **GameStock** — belongs to `Game` + `Stock`; `current_price` (cents, 0–200); one per stock per game; initialized at 100
- **Game** — `name`, `invite_code` (6-char uppercase alphanumeric via `SecureRandom.alphanumeric(6).upcase`), `host` (belongs to User), `status`, `current_turn`, `duration`, `starts_at`, `ends_at`, `remaining_time`, `rolls_remaining_this_turn` (default 2)
  - Status state machine: `waiting` → `in_progress` → `paused` (solo only) → `completed`
  - `active_player`: `players.active.order(:turn_position).offset(current_turn % active_player_count).first`
- **Player** — `user_id`, `game_id`, `cash` (cents, default 500_000), `status` (active/dropped), `turn_position` (join order)
- **Holding** — `player_id`, `game_stock_id`, `quantity` (integer, multiples of 500)
- **GameTransaction** — `player_id`, `game_stock_id`, `transaction_type` (buy/sell/dividend/split/worthless_reset), `quantity`, `price_at_time`, `total_amount`, `turn_number`
  - Use `GameTransaction` not `Transaction` (Rails reserved name)
- **DiceRoll** — `game_id`, `player_id`, `turn_number`, `stock_rolled` (references Stock), `direction` (up/down/dividend), `amount` (cents: 5/10/20)
- **Message** — `user_id`, `game_id`, `body` (max 200 chars, UTF-8 for emoji)

---

## GraphQL API

### Queries
- `game(id/invite_code)` — single game; includes `endsAt`, remaining time, `rollsRemainingThisTurn`
- `games` — list available/active games
- `transactions(game_id)` — paginated game history

### Mutations
| Mutation | Description |
|----------|-------------|
| `CreateGame` | duration preset (15/30/60/90 min), generates invite code, 6 GameStocks at $1.00, status=waiting |
| `StartGame` | host-only; waiting→in_progress; computes `ends_at`; schedules `GameClockExpiryJob` |
| `JoinGame` | join via invite code; restore state if rejoining; else new Player($5k, 0 shares) |
| `LeaveGame` | drop out, preserve state |
| `PauseGame` | solo only; stores `remaining_time`, stops clock |
| `ResumeGame` | solo only; recomputes `ends_at = Time.current + remaining_time`; reschedules job |
| `RollDice` | invokes DiceRollingService; returns roll result + `rollsRemaining`; active player only |
| `BuyShares` | active player after both rolls; lots of 500; validate cash |
| `SellShares` | active player after both rolls; lots of 500; validate shares owned |
| `EndTurn` | requires both rolls done; advances `current_turn`; resets `rolls_remaining_this_turn` to 2 |
| `SendMessage` | post chat message |

### Subscriptions
| Subscription | Trigger |
|-------------|---------|
| `GameStarted` | Host starts game |
| `GameStockPriceUpdated` | After each dice roll affects a stock |
| `DiceRolled` | After each roll |
| `LeaderboardUpdated` | After net worth changes |
| `TurnChanged` | When active player changes |
| `PlayerPresenceChanged` | Connect/disconnect via Action Cable |
| `GameEnded` | Clock expires; includes final rankings |
| `MessageReceived` | New chat message |

Trigger pattern: `StockTickerSchema.subscriptions.trigger("event_name", {args}, object)`

### Mutation Pattern
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

---

## Service Objects
- **DiceRollingService** — dice logic, price changes, split/worthless/dividend events, auto-roll for dropped players
- **TradingService** — buy/sell, validates trade window open and player is active
- Keep business logic in services, not models or mutations

---

## Identity & Action Cable
- Session-based; `current_user` helper reads `session[:user_id]`
- `ApplicationCable::Connection` authenticates via Rails session cookie: read `request.session[:user_id]`, set `current_user` (reject unknown/missing)
- Track presence: connect/disconnect callbacks trigger `PlayerPresenceChanged`

---

## UI Design System

### Theme
- Dark financial terminal aesthetic
- Background: `#0F172A` | Text: `#E2E8F0`
- Fonts (Google Fonts): **Inter** (UI text, weights 400–900), **JetBrains Mono** (prices/numbers/dice)

### Stock Colors & Symbols
| Stock | Symbol | Color |
|-------|--------|-------|
| Grain | GRN | #D97706 |
| Industrial | IND | #EF4444 |
| Bonds | BNDS | #3B82F6 |
| Oil | OIL | #10B981 |
| Silver | SLVR | #94A3B8 |
| Gold | GOLD | #F59E0B |

### Player Colors (by join order, cycle if >4)
| Position | Color |
|----------|-------|
| 1 | #3B82F6 |
| 2 | #EF4444 |
| 3 | #22C55E |
| 4 | #F59E0B |

### Semantic Colors
- Up/gain: `#22C55E` | Down/loss: `#EF4444` | Dividend: `#F59E0B` | Split: `#3B82F6` | Crash: `#EF4444`

### Number Formatting
- **Prices**: `$X.XX` (2 decimal places) — `(cents / 100).toFixed(2)`
- **Money**: `$X,XXX` (thousand separators, no decimals) — `toLocaleString('en-US')`
- **Shares**: thousand separators (e.g., "1,500 shares")

### Screen Architecture (screen-switching pattern)
Only one `.screen` visible at a time (toggled via `.active` class). 5 screens:
1. **Username Entry** — pick display name, POST to `/join`
2. **Home / Game Lobby** — create game or join by code; open games list
3. **Waiting Room** — invite code display, player list, Start Game (host)
4. **Game Board** — three-column layout (260px log | 1fr board | 300px sidebar)
5. **Game Over / Results** — final rankings, profit/loss, Play Again

### Game Board Layout
```css
.game-layout {
  display: grid;
  grid-template-columns: 260px 1fr 300px;
  gap: 0;
}
```
- **Left**: Game Log (last roll dice badges + net worth tracker with change since last roll)
- **Center**: Stock board (1×6 grid, cards created ONCE via `initStockBoard()`, updated in-place via `renderStockBoard()`) + Dice Area + trade controls inline on cards during trading
- **Right**: Portfolio panel, Scoreboard, Chat

### Render Cycle (called on every state change)
1. `initStockBoard()` — creates 6 static card DOM elements once
2. `renderStockBoard()` — updates price/change text; injects trade controls during trading
3. `renderPhaseBanner()` — rolling/trading phase, active player
4. `renderDiceArea()` — show/hide dice and roll button
5. `renderPlayerPanel()` — cash, net worth, holdings
6. `renderScoreboard()` — all players ranked
7. `renderEventTicker()` — scrolling event feed
8. `renderRoundDisplay()` — turn number badge
9. `renderGameLog()` — last roll + net worth tracker

---

## Dev Environment

### Start (Docker — primary)
```bash
colima start --cpu 4 --memory 6 --vm-type vz --vz-rosetta
docker-compose up --build
# First time only:
docker-compose exec app bin/docker-setup
```

### Common Docker Commands
```bash
docker-compose exec app bin/rails console
docker-compose exec app bin/rails test
docker-compose logs -f app
docker-compose down
docker-compose down -v          # wipe all data
colima stop
```

### Local Dev (no Docker)
```bash
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/opt/postgresql@16/bin:$PATH"
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

### Tests
```bash
docker-compose exec app bin/rails test   # Docker
bundle exec rails test                   # Local
```

---

## Contributing Workflow
1. Branch off `develop`: `git checkout develop && git checkout -b feature/my-feature`
2. PRs target `develop`; `main` is stable/production
3. `develop` merges into `main` after testing

---

## Key Files
- `db/seeds.rb` — seeds the 6 static Stock records
- `app/services/DiceRollingService` — core game engine logic
- `app/jobs/GameClockExpiryJob` — handles game expiry
- `docker-compose.yml` — app + PostgreSQL + Redis
- `config/importmap.rb` — JS module pins (bare specifiers)
- `RULES.md` — full game rules document
