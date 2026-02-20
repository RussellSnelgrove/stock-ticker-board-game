# Stock Ticker App

A digital version of the classic Stock Ticker board game, built with Ruby on Rails and a GraphQL API.

## Game Overview

Players buy and sell shares in 6 commodities: **Gold, Silver, Bonds, Grain, Industrial, and Oil**. Each turn, dice rolls determine which stock moves, the direction (Up, Down, or Dividend), and the amount. Stock prices range from $0.00 to $2.00. Stocks split at $2.00 or become worthless at $0. The player with the highest net worth at the end wins.

## Tasks

### 1. Create a basic Ruby on Rails app

- [ ] Install Ruby and Rails
- [ ] Scaffold a new Rails project (`rails new stock-ticker`)
- [ ] Set up the database (Yugabyte)
- [ ] Verify the app runs locally (`rails server`)
- [ ] Set up a Git repository and make an initial commit

### 2. Add Sorbet for type safety

- [ ] Install the `sorbet` and `tapioca` gems
- [ ] Run `tapioca init` to generate RBI files
- [ ] Configure Sorbet strictness levels per file
- [ ] Add typed signatures (`sig`) to models, services, and controllers as they are built
- [ ] Integrate Sorbet type checking into the development workflow

### 3. Set up GraphQL

- [ ] Add the `graphql-ruby` gem to the Gemfile
- [ ] Run the GraphQL generator (`rails generate graphql:install`)
- [ ] Configure the `GraphqlController` with a single `/graphql` endpoint
- [ ] Set up the base `StockTickerSchema` with query, mutation, and subscription root types
- [ ] Configure Action Cable as the GraphQL subscriptions transport
- [ ] Add GraphiQL or GraphQL Playground for development (via `graphiql-rails` gem)
- [ ] Add Sorbet type signatures to the schema and controller
- [ ] Write a smoke test that queries the GraphQL endpoint successfully

### 4. Build the Stock Ticker data models

- [ ] Create a `Stock` model for the 6 commodities (Gold, Silver, Bonds, Grain, Industrial, Oil)
- [ ] Each stock has a name, current price (range $0.00–$2.00), and status (active/worthless)
- [ ] Create a `Game` model to track game state (status, current turn, start time, end time)
- [ ] Create a `Player` model linked to a User and a Game (starting cash: $5,000)
- [ ] Create a `Holding` model to track shares owned per player per stock
- [ ] Create a `Transaction` model to log all buys, sells, dividends, and splits
- [ ] Create a `DiceRoll` model to record each turn's roll results
- [ ] Add validations and associations between all models
- [ ] Add Sorbet type signatures to all models
- [ ] Define GraphQL types for each model (`StockType`, `GameType`, `PlayerType`, `HoldingType`, `TransactionType`, `DiceRollType`)
- [ ] Seed the database with the 6 default stocks at a starting price of $1.00
- [ ] Write unit tests for all model validations and associations

### 5. Implement game sessions

- [ ] Create a `Session` model to represent a game session (name, invite code, host, status)
- [ ] Define a `CreateSession` mutation to start a new game session
- [ ] Define a `JoinSession` mutation to join via invite code
- [ ] Define a `LeaveSession` mutation to drop out while preserving state
- [ ] Define a `RejoinSession` mutation to rejoin a previously left game
- [ ] Add a `sessions` query to list available and active games
- [ ] Add a `session` query to fetch a single session by ID or invite code
- [ ] Support **solo games** — a single player can create and play alone
- [ ] Allow solo players to **save and resume** a game later via a `SaveGame` mutation
- [ ] Allow players to **join an ongoing game** mid-session
- [ ] Track player presence (online/offline) within a session
- [ ] Write unit tests for session mutations and queries

### 6. Implement the dice and turn mechanics

- [ ] Build a dice rolling service that produces 3 results per turn:
  - **Die 1**: Which stock is affected (Gold, Silver, Bonds, Grain, Industrial, Oil)
  - **Die 2**: Direction (Up, Down, or Dividend)
  - **Die 3**: Amount ($1 or $5 movement)
- [ ] Define a `RollDice` mutation that invokes the dice service and returns the roll result
- [ ] Apply price changes to the affected stock after each roll
- [ ] Handle **stock splits** — when a stock reaches $2.00, all holders' shares double and price resets
- [ ] Handle **worthless stocks** — when a stock drops to $0, all shares are wiped out
- [ ] Handle **dividends** — pay out a percentage of the stock's current value to all holders
- [ ] Enforce turn order so players roll and trade in sequence
- [ ] Skip turns for players who have dropped out
- [ ] Write unit tests for the `RollDice` mutation, price changes, splits, worthless stocks, and dividends

### 7. Implement buying and selling

- [ ] Define a `BuyShares` mutation to purchase shares at the current stock price
- [ ] Define a `SellShares` mutation to sell shares at the current stock price
- [ ] Validate sufficient cash for purchases (return GraphQL user errors on failure)
- [ ] Validate sufficient shares for sales (return GraphQL user errors on failure)
- [ ] Shares are bought/sold in lots (e.g., multiples of 100)
- [ ] Update player cash and holdings after each transaction
- [ ] Log all transactions for game history
- [ ] Add a `transactions` query to fetch game history with pagination
- [ ] Write unit tests for buy/sell mutations, validation errors, and edge cases

### 8. Add Memcached caching layer

- [ ] Set up a Memcached instance (local and Docker)
- [ ] Cache active game state (stock prices, player holdings, turn info) in Memcached
- [ ] Periodically write cached game state back to Yugabyte
- [ ] Invalidate cache on critical events (game over, player join/leave)
- [ ] Use caching for the leaderboard and session listings
- [ ] Write tests to verify cache read/write and persistence sync

### 9. Build the game UI

- [ ] Create a game lobby powered by GraphQL queries (`sessions`, `session`)
- [ ] Display available sessions and active games
- [ ] Build the main game board showing all 6 stocks and their current prices (via GraphQL query)
- [ ] Display each player's cash balance and holdings
- [ ] Show player presence indicators (online/offline/dropped) via subscriptions
- [ ] Add a dice roll animation triggered by the `RollDice` mutation response
- [ ] Build buy/sell controls that call `BuyShares` / `SellShares` mutations
- [ ] Show a transaction history / activity feed via the `transactions` query
- [ ] Build a net worth leaderboard (cash + portfolio value) with live subscription updates
- [ ] Add a save game button for solo players (calls `SaveGame` mutation)
- [ ] Add a game-over screen with final rankings

### 10. Add real-time updates with GraphQL subscriptions

- [ ] Define a `StockPriceUpdated` subscription to push price changes to all players
- [ ] Define a `DiceRolled` subscription to broadcast roll results in real time
- [ ] Define a `LeaderboardUpdated` subscription to push net worth changes
- [ ] Define a `TurnChanged` subscription to notify players when it's their turn
- [ ] Define a `PlayerPresenceChanged` subscription for join/leave/rejoin events
- [ ] Configure Action Cable as the transport layer for GraphQL subscriptions
- [ ] Write integration tests for subscription delivery

### 11. Add a real-time chat room

- [ ] Create a `Message` model (user, game, body, timestamp)
- [ ] Define a `SendMessage` GraphQL mutation to post chat messages
- [ ] Define a `MessageReceived` GraphQL subscription for real-time message delivery
- [ ] Build a chat room UI within the game view
- [ ] Build out an emoji functionality so users can use emojis in the chat room
- [ ] Display active players in the chat
- [ ] Write tests for the mutation, subscription, and message delivery

### 12. Add authentication and external access

- [ ] Add user authentication (Devise or a custom solution)
- [ ] Add a `context` hash to `GraphqlController` that resolves the current user from the session/token
- [ ] Guard mutations and queries with authentication checks via GraphQL authorization
- [ ] Implement password-protected access for external users
- [ ] Set up HTTPS / SSL for secure connections
- [ ] Configure the app for external network access (port forwarding, domain, or tunneling)
- [ ] Add role-based access control (admin/host vs. player) enforced at the GraphQL layer
- [ ] Write tests for authentication and authorization in GraphQL context

### 13. Dockerize the app

- [ ] Write a `Dockerfile` for the Rails app
- [ ] Create a `docker-compose.yml` with app, Yugabyte, Memcached, and Redis services
- [ ] Configure environment variables via `.env` file
- [ ] Test building and running the app in Docker
- [ ] Document Docker setup instructions in this README

### 14. Write the game rules document

- [ ] Create a `RULES.md` file with full game rules and how to play
- [ ] Include commodity descriptions and starting prices
- [ ] Document dice mechanics (3-die system, outcomes)
- [ ] Explain stock splits, worthless stocks, and dividends
- [ ] Cover buying/selling rules and lot sizes
- [ ] Describe session types (solo vs. multiplayer)
- [ ] Add win conditions and scoring
