# Stock Ticker

A real-time multiplayer web app based on the classic Stock Ticker board game. Players buy and sell shares in Grain, Industrial, Bonds, Oil, Silver, and Gold. With dice-driven price swings, stock splits, and dividends. Built with Ruby on Rails, GraphQL (graphql-ruby), and Redis. Supports solo play, drop-in/drop-out sessions, and live chat.

## Table of Contents

- [Game Overview](#game-overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Running Tests](#running-tests)
- [Project Structure](#project-structure)
- [Contributing](#contributing)

## Game Overview

Stock Ticker is a classic board game where players compete to build the highest net worth by trading shares in 6 commodities: Grain, Industrial, Bonds, Oil, Silver, and Gold. Each game maintains its own stock prices — all stocks start at **$1.00** per game. Each turn, the active player rolls three dice **twice**. After each roll, the market moves:

| Die   | Determines              | Possible Values                             |
| ----- | ----------------------- | ------------------------------------------- |
| Die 1 | Which stock is affected | Grain, Industrial, Bonds, Oil, Silver, Gold |
| Die 2 | Direction of movement   | Up, Down, Dividend                          |
| Die 3 | Amount of change        | $0.05, $0.10 or $0.20                       |

- **Stock Splits** — When a stock reaches $2.00, all holders' shares double and the price resets to $1.00.
- **Worthless Stocks** — When a stock drops to $0, all holders' shares are immediately removed and the stock resets to $1.00.
- **Dividends** — When a dividend is rolled for a stock priced at $1.00 or higher, all holders receive a payout per share based on Die 3 (5%, 10%, or 20% of the stock's current price). Dividends rolled for stocks below $1.00 have no effect.

**Turn sequence**: Roll 1 → market moves → Roll 2 → market moves → trade (buy/sell) → end turn.

When creating a game, the host selects a play duration (e.g., 30, 60, or 90 minutes). Players join via an invite code while the game is in the lobby. Once the host starts the game, the clock begins counting down. Turn order follows join order. When the timer reaches zero, all trading is frozen and the player with the highest net worth (cash + portfolio value) wins.

## Features

- **No login required** — Just pick a username and start playing
- **Multiplayer games** — Create a game and invite friends via a shareable code
- **Game clock** — Host selects a play duration at game creation; a countdown timer ends the game automatically
- **Two rolls per turn** — Each player rolls dice twice before their trading window opens
- **Solo play** — Play alone with the ability to pause and resume later
- **Drop-in/drop-out** — Players can leave and rejoin games without losing their state
- **Game log** — Left sidebar shows the last dice roll and all players' net worth changes in real time
- **GraphQL API** — All game data exposed through a single, flexible GraphQL endpoint
- **Real-time updates** — Stock prices, dice rolls, and leaderboards update live via GraphQL subscriptions
- **In-game chat** — Talk with other players during the game

## Tech Stack

| Component        | Technology                                     |
| ---------------- | ---------------------------------------------- |
| Framework        | Ruby on Rails                                  |
| API              | GraphQL (graphql-ruby)                         |
| Database         | PostgreSQL (Yugabyte-compatible for production) |
| Caching/Real-time| Redis (caching + Action Cable + GraphQL Subscriptions) |
| Identity         | Session-based (pick a username, no login required) |
| Containerization | Colima + Docker CLI + Docker Compose           |

## Getting Started

### Option 1: Docker (primary method)

The app runs via Docker Compose using [Colima](https://github.com/abiosoft/colima) as the container runtime. All services (PostgreSQL, Redis) are containerized.

**Prerequisites**: Install via Homebrew:

```bash
brew install colima docker docker-compose
```

**Start the container runtime**:

```bash
colima start --cpu 4 --memory 6 --vm-type vz --vz-rosetta
```

**Run the app**:

```bash
# Build and start all services
docker-compose up --build

# First time only — in a second terminal, set up the database
docker-compose exec app bin/docker-setup
```

Visit `http://localhost:3000` to start playing.

**Useful commands**:

```bash
docker-compose down          # stop all containers
docker-compose down -v       # stop and wipe all data (fresh start)
docker-compose logs -f app   # tail the Rails logs
docker-compose exec app bin/rails console  # open a Rails console
colima status                # check if the VM is running
colima stop                  # stop the VM when done for the day
```

### Option 2: Local development (without Docker)

For developers who cannot run containers (e.g., Docker/Podman blocked by device policy).

**Prerequisites**:

- Ruby 3.3.x (via rbenv: `brew install rbenv ruby-build && rbenv install 3.3.7`)
- PostgreSQL (`brew install postgresql@16 && brew services start postgresql@16`)
- Redis (`brew install redis && brew services start redis`)

**Setup**:

```bash
# Add to ~/.zshrc for persistence
eval "$(rbenv init - zsh)"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Install gems and set up the database
bundle install
bin/rails db:create db:migrate db:seed

# Start the server
bin/rails server
```

Visit `http://localhost:3000` to start playing.

## Running Tests

```bash
# Inside Docker
docker-compose exec app bin/rails test

# Or locally
bundle exec rails test
```

## Project Structure

```
stock-ticker/
├── app/
│   ├── channels/        # Action Cable channels (GraphQL subscriptions transport)
│   ├── controllers/     # GraphqlController, GamesController, SessionsController
│   ├── graphql/
│   │   ├── types/       # GraphQL object types (GameStockType, GameType, PlayerType, etc.)
│   │   ├── mutations/   # GraphQL mutations (BuyShares, SellShares, RollDice, etc.)
│   │   └── subscriptions/ # GraphQL subscriptions (price updates, chat, turn notifications)
│   ├── models/          # Stock, GameStock, Game, Player, Holding, GameTransaction, DiceRoll, Message, User
│   ├── services/        # DiceRollingService, TradingService
│   ├── jobs/            # GameClockExpiryJob
│   └── views/           # Game board, lobby, chat, and leaderboard UI
├── config/
├── db/
│   ├── migrate/         # Database migrations
│   └── seeds.rb         # The 6 default stock commodities
├── Dockerfile           # Production Dockerfile
├── Dockerfile.dev       # Development Dockerfile
├── docker-compose.yml   # App + PostgreSQL + Redis
├── RULES.md             # Full game rules and how to play
└── README.md
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m "Add my feature"`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request
