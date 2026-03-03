---
name: stock-ticker
description: Build and modify the Stock Ticker multiplayer board game. Use when working on game logic, UI, GraphQL API, Docker setup, models, or any file in this project. Covers game rules, architecture decisions, known gotchas, and project constraints.
---

# Stock Ticker Game

Multiplayer web adaptation of the classic Stock Ticker board game. Ruby on Rails + GraphQL + Redis + vanilla JS.

## Project Docs

Read these before making changes:

- [stock-ticker-task-list.md](../../../stock-ticker-task-list.md) — Full build spec with all tasks, game rules, UI spec, and constraints
- [README.md](../../../README.md) — Setup instructions (Docker and local), tech stack, project structure
- [OPEN-ISSUES.md](../../../OPEN-ISSUES.md) — Unresolved items that need decisions before implementing

## Hard Constraints

Violating any of these will break the build or conflict with the project design:

1. **No authentication libraries**. No Devise, no bcrypt, no auth gems. Users pick a display name and play via session cookie.
2. **No rbenv or rvm**. Use chruby or Homebrew Ruby for local dev. Docker handles Ruby in containers.
3. **Docker-first via Colima**. Primary dev method is `docker-compose up`. Use `brew install colima docker docker-compose`. Never assume local services exist.
4. **Local dev mode must also work** for devs who can't run containers.
5. **PostgreSQL in Docker, not Yugabyte**. Yugabyte doesn't run on ARM64/Colima. PostgreSQL is wire-compatible.
6. **`GameTransaction` not `Transaction`**. Rails reserves `Transaction` as a method name on ActiveRecord::Base.
7. **Stock card order is fixed**: Grain, Industrial, Bonds, Oil, Silver, Gold. Always this order in seed data, GraphQL responses, and UI rendering.

## Architecture

```
Browser (vanilla JS + importmap)
  ↕ fetch + Action Cable WebSocket
GraphqlController → StockTickerSchema
  ├── Queries: games, game, me, transactions
  ├── Mutations: CreateGame, StartGame, JoinGame, LeaveGame, PauseGame,
  │              RollDice, BuyShares, SellShares, EndTurn, SendMessage
  └── Subscriptions: GameStarted, GameStockPriceUpdated, DiceRolled,
                     TurnChanged, PlayerPresenceChanged, GameEnded, MessageReceived
Services: DiceRollingService, TradingService
Jobs: GameClockExpiryJob
```

## Game Mechanics Quick Reference

- **6 stocks**: Grain, Industrial, Bonds, Oil, Silver, Gold — each with a unique color
- **Prices in cents** (integer): 100 = $1.00, range 0–200
- **2 rolls per turn**, then trade, then end turn
- **Stock split** at $2.00: cap, double shares, reset to $1.00
- **Worthless** at $0: wipe shares, reset to $1.00 (stock comes back)
- **Dividends**: Die 3 maps to 5%/10%/20% of price per share; only when stock >= $1.00
- **Lots of 500 shares**
- **Game clock**: host picks duration, countdown timer, auto-ends
- **Turn order = join order**
- **`rollsRemainingThisTurn`**: computed server field the client MUST sync from to prevent desync

## Known Gotchas

These caused bugs during the first build. Check for them in code review:

| Issue | Fix |
|-------|-----|
| Rails 8.1 ships `solid_cache`, `solid_queue`, `solid_cable` | Remove from Gemfile, delete config/cache.yml, config/queue.yml, db/*_schema.rb, puma plugin |
| PostgreSQL health check fails silently | Must use `pg_isready -U stock_ticker -d stock_ticker_development` (the `-d` flag is required) |
| importmap uses bare specifiers | `import X from "module_name"` not `"./module_name"`. Pin in config/importmap.rb |
| `.ruby-version` breaks host shell | Delete it. Add to `.dockerignore`. Ruby version is in Dockerfile.dev |
| Stock cards jump on re-render | Create cards once via `initStockBoard()`, update only text content via `renderStockBoard()`. Never replace innerHTML on the board. |
| Roll count desyncs client/server | Client MUST read `rollsRemainingThisTurn` from game object after every mutation. Never hardcode `rollsRemaining = 2`. |
| `stock-change` shows wrong diff | Shows change from last roll that affected this stock, NOT overall change from $1.00. Track previous price per stock on the client. |
| Action Cable needs session access | `ApplicationCable::Connection` reads `request.session[:user_id]`. Set `config.action_cable.disable_request_forgery_protection = true` in development. |
| `config.hosts` blocks Docker requests | Add `config.hosts.clear` in development.rb for Docker and network access. |

## UI Three-Column Layout

```
┌──────────────────────────────────────────────────────────────────┐
│ Header: Title | Turn N | Clock MM:SS                        [Pause] │
├──────────────────────────────────────────────────────────────────┤
│ Event Ticker (scrolling marquee)                                     │
├──────────────────────────────────────────────────────────────────┤
│ Phase Banner: Rolling — Player Name — Roll 1 of 2                    │
├─────────────┬────────────────────────────────┬───────────────────┤
│ GAME LOG    │ STOCK BOARD (1x6 static cards) │ YOUR PORTFOLIO    │
│             │ [GRN][IND][BNDS][OIL][SLVR][GOLD] │ Cash / Net Worth │
│ Last Roll:  │                                │ Holdings          │
│ GRN UP 10¢  │ DICE AREA                      ├───────────────────┤
│             │ [Stock][Action][Amount]         │ STANDINGS         │
│ Net Worth:  │ [Roll Dice (1 of 2)]           │ 1. Player $X,XXX  │
│ P1 $5,200 ↑ │                                │ 2. Player $X,XXX  │
│ P2 $4,800 ↓ │ or TRADE CONTROLS              ├───────────────────┤
│             │ (inline on cards)              │ CHAT              │
│             │ [Done Trading]                 │ messages + input   │
├─────────────┴────────────────────────────────┴───────────────────┤
│ 260px          flexible                        300px               │
└──────────────────────────────────────────────────────────────────┘
```

## File Naming Conventions

| Type | Location | Example |
|------|----------|---------|
| Models | `app/models/` | `game_stock.rb`, `game_transaction.rb` |
| GraphQL Types | `app/graphql/types/` | `game_stock_type.rb` |
| Mutations | `app/graphql/mutations/` | `roll_dice.rb`, `buy_shares.rb` |
| Subscriptions | `app/graphql/subscriptions/` | `game_ended.rb` |
| Services | `app/services/` | `dice_rolling_service.rb`, `trading_service.rb` |
| Jobs | `app/jobs/` | `game_clock_expiry_job.rb` |
| JS | `app/javascript/` | `game_client.js` (pin as `"game_client"` in importmap) |
