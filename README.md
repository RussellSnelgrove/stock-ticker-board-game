# Stock Ticker

A real-time multiplayer web app based on the classic Stock Ticker board game. Players buy and sell shares in Gold, Silver, Bonds, Grain, Industrial, and Oil. With dice-driven price swings, stock splits, and dividends. Built with Ruby on Rails, GraphQL (graphql-ruby), Memcached, and Yugabyte. Supports solo play, drop-in/drop-out sessions, and live chat.

## Table of Contents

- [Game Overview](#game-overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Docker Setup](#docker-setup)
- [Running Tests](#running-tests)
- [Project Structure](#project-structure)
- [Contributing](#contributing)

## Game Overview

Stock Ticker is a classic board game where players compete to build the highest net worth by trading shares in 6 commodities. All stocks start the game at **$1.00**. Each turn, three dice are rolled to determine:

| Die   | Determines              | Possible Values                             |
| ----- | ----------------------- | ------------------------------------------- |
| Die 1 | Which stock is affected | Gold, Silver, Bonds, Grain, Industrial, Oil |
| Die 2 | Direction of movement   | Up, Down, Dividend                          |
| Die 3 | Amount of change        | $0.05, $0.10 or $0.20                       |

- **Stock Splits** — When a stock reaches $2.00, all holders' shares double and the price resets.
- **Worthless Stocks** — When a stock drops to $0, all shares are wiped out.
- **Dividends** — All holders receive a payout based on the stock's current value.

The game ends at an agreed-upon time, and the player with the highest net worth (cash + portfolio value) wins.

## Features

- **Multiplayer sessions** — Create a game and invite friends via a shareable code
- **Solo play** — Play alone with the ability to save and resume later
- **Drop-in/drop-out** — Players can leave and rejoin games without losing their state
- **GraphQL API** — All game data exposed through a single, flexible GraphQL endpoint
- **Real-time updates** — Stock prices, dice rolls, and leaderboards update live via GraphQL subscriptions
- **In-game chat** — Talk with other players during the game
- **Type-safe codebase** — Sorbet for static type checking across the app

## Tech Stack

| Component        | Technology                                     |
| ---------------- | ---------------------------------------------- |
| Framework        | Ruby on Rails                                  |
| API              | GraphQL (graphql-ruby)                         |
| Database         | Yugabyte                                       |
| Caching          | Memcached                                      |
| Real-time        | GraphQL Subscriptions via Action Cable + Redis |
| Type Checking    | Sorbet                                         |
| Authentication   | Devise                                         |
| Containerization | Docker + Docker Compose                        |

## Getting Started

### Prerequisites

- Ruby 3.x
- Rails 7.x
- Yugabyte (or PostgreSQL for local development)
- Redis
- Memcached

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/stock-ticker.git
cd stock-ticker

# Install dependencies
bundle install

# Set up the database
rails db:create db:migrate db:seed

# Start the server
rails server
```

Visit `http://localhost:3000` to start playing.

## Docker Setup

```bash
# Build and start all services
docker-compose up --build

# Run database migrations
docker-compose exec app rails db:create db:migrate db:seed
```

The `docker-compose.yml` includes the Rails app, Yugabyte, Memcached, and Redis.

## Running Tests

```bash
# Run the full test suite
bundle exec rails test

# Run Sorbet type checks
bundle exec srb tc
```

## Project Structure

```
stock-ticker/
├── app/
│   ├── channels/        # Action Cable channels (GraphQL subscriptions transport)
│   ├── controllers/     # GraphqlController (single endpoint)
│   ├── graphql/
│   │   ├── types/       # GraphQL object types (StockType, GameType, PlayerType, etc.)
│   │   ├── mutations/   # GraphQL mutations (BuyShares, SellShares, RollDice, etc.)
│   │   ├── queries/     # GraphQL queries (game state, leaderboard, session list)
│   │   └── subscriptions/ # GraphQL subscriptions (price updates, chat, turn notifications)
│   ├── models/          # Stock, Game, Player, Holding, Transaction, DiceRoll
│   ├── services/        # DiceRollingService, TradingService, CacheService
│   └── views/           # Game board, lobby, chat, and leaderboard UI
├── config/
├── db/
│   ├── migrate/         # Database migrations
│   └── seeds.rb         # Default stock data
├── test/                # Unit and integration tests
├── Dockerfile
├── docker-compose.yml
├── RULES.md             # Full game rules and how to play
└── README.md
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m "Add my feature"`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request
