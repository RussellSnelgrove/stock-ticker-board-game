# Stock Ticker App

A digital version of the classic Stock Ticker board game, built with Ruby on Rails and a GraphQL API.

## Game Overview

Players buy and sell shares in 6 commodities: **Gold, Silver, Bonds, Grain, Industrial, and Oil**. Each game maintains its own stock prices, starting at $1.00. Each turn, dice rolls determine which stock moves, the direction (Up, Down, or Dividend), and the amount. Stock prices range from $0.00 to $2.00. Stocks split at $2.00; stocks that drop to $0 are wiped and reset to $1.00. Dividends are only paid when the stock is priced at $1.00 or higher. Each game runs on a countdown timer selected by the host. When the clock reaches zero, the player with the highest net worth wins.

## Tasks

### 1. Create a basic Ruby on Rails app

- [ ] Install Ruby and Rails
- [ ] Scaffold a new Rails project (`rails new stock-ticker`)
- [ ] Set up the database (Yugabyte)
- [ ] Verify the app runs locally (`rails server`)
- [ ] Set up a Git repository and make an initial commit

### 2. Set up GraphQL

- [ ] Add the `graphql-ruby` gem to the Gemfile
- [ ] Run the GraphQL generator (`rails generate graphql:install`)
- [ ] Configure the `GraphqlController` with a single `/graphql` endpoint
- [ ] Set up the base `StockTickerSchema` with query, mutation, and subscription root types
- [ ] Configure Action Cable as the GraphQL subscriptions transport
- [ ] Add GraphiQL or GraphQL Playground for development (via `graphiql-rails` gem)
- [ ] Write a smoke test that queries the GraphQL endpoint successfully

### 3. Add Sorbet for type safety

- [ ] Install the `sorbet` and `tapioca` gems
- [ ] Run `tapioca init` to generate RBI files (including RBIs for `graphql-ruby`)
- [ ] Configure Sorbet strictness levels per file
- [ ] Add typed signatures (`sig`) to the GraphQL schema, controller, models, and services as they are built
- [ ] Integrate Sorbet type checking into the development workflow

### 4. Build the Stock Ticker data models

- [ ] Create a `User` model via Devise (email, password, display name) for authentication and player identity
- [ ] Create a `Stock` model as a static lookup for the 6 commodities (Gold, Silver, Bonds, Grain, Industrial, Oil)
- [ ] Create a `GameStock` model (belongs to `Game` and `Stock`) to track each stock's price and status within a game
  - Fields: `current_price` (range $0.00–$2.00)
  - Each game gets its own set of 6 `GameStock` records initialized at $1.00
- [ ] Create a `Game` model to represent a game session and its state:
  - Fields: `name`, `invite_code`, `host` (belongs to `User`), `status`, `current_turn`, `duration`, `starts_at`, `ends_at`, `remaining_time`
  - Status state machine: `waiting` (lobby, accepting players) -> `in_progress` (clock running) -> `paused` (solo only) -> `completed` (timer expired)
  - Only mutations valid for the current status should be accepted (e.g., no rolling in "waiting", no trading in "completed")
- [ ] Create a `Player` model linked to a User and a Game
  - Fields: `cash` (starting at $5,000), `status` (active/dropped), `turn_position` (integer, set by join order)
- [ ] Create a `Holding` model to track shares owned per player per `GameStock`
  - Fields: `player_id`, `game_stock_id`, `quantity` (integer, multiples of 500)
- [ ] Create a `Transaction` model to log all buys, sells, dividends, and splits
  - Fields: `player_id`, `game_stock_id`, `transaction_type` (buy/sell/dividend/split/worthless_reset), `quantity`, `price_at_time`, `total_amount`, `turn_number`
- [ ] Create a `DiceRoll` model to record each turn's roll results
  - Fields: `game_id`, `player_id`, `turn_number`, `stock_rolled` (references `Stock`), `direction` (up/down/dividend), `amount` ($0.05/$0.10/$0.20)
- [ ] Add validations and associations between all models
- [ ] Add Sorbet type signatures to all models
- [ ] Define GraphQL types for each model (`GameStockType`, `GameType`, `PlayerType`, `HoldingType`, `TransactionType`, `DiceRollType`)
- [ ] Seed the database with the 6 static `Stock` records
- [ ] Write unit tests for all model validations and associations

### 5. Implement game lifecycle

- [ ] Define a `CreateGame` mutation (accepts a `duration` in minutes, generates an invite code, initializes 6 `GameStock` records at $1.00, sets status to "waiting" — clock does **not** start yet)
- [ ] Define a `StartGame` mutation (host-only) to transition the game from "waiting" to "in_progress", compute `ends_at` from the duration, and schedule the game clock expiry job
- [ ] Define a `JoinGame` mutation to join via invite code (if the player was previously in the game, restore their state; otherwise create a new `Player` record with $5,000 cash and 0 shares)
- [ ] Define a `LeaveGame` mutation to drop out while preserving state
- [ ] Add a `games` query to list available and active games
- [ ] Add a `game` query to fetch a single game by ID or invite code (includes `ends_at` and remaining time)
- [ ] Implement game clock expiry — schedule a background job (Active Job) that fires at `ends_at` to freeze all trading, compute final net worth for all players, and set game status to "completed"
- [ ] Broadcast a `GameEnded` event when the timer expires with final rankings
- [ ] Support **solo games** — only 1 player; host creates and starts the game alone
- [ ] Multiplayer games have **no player limit**
- [ ] Turn order is determined by **join order**; mid-game joins are appended to the end of the turn order
- [ ] Mid-game joins always start with **$5,000 cash and 0 shares** regardless of when they join; they must wait for their turn to trade
- [ ] Allow solo players to **pause and resume** a game later via a `PauseGame` mutation (stores `remaining_time` and stops the clock; `JoinGame` resumes the clock and recomputes `ends_at`)
- [ ] Track player presence (online/offline) within a game
- [ ] Write unit tests for game lifecycle mutations, game clock expiry, and queries

### 6. Implement the dice and turn mechanics

- [ ] Build a dice rolling service that produces 3 results per turn (all dice are **uniformly weighted** — each outcome is equally likely):
  - **Die 1**: Which stock is affected (1/6 each: Gold, Silver, Bonds, Grain, Industrial, Oil)
  - **Die 2**: Direction (1/3 each: Up, Down, or Dividend)
  - **Die 3**: Amount (1/3 each: $0.05, $0.10 or $0.20 movement)
- [ ] Define a `RollDice` mutation that invokes the dice service and returns the roll result
- [ ] Apply price changes to the affected `GameStock` after each roll
- [ ] Share supply is **unlimited** — players may buy as many shares as they can afford
- [ ] **Price floor**: $0.00 is the absolute minimum; any roll that would take a stock below $0 triggers the worthless behavior (wipe shares, reset to $1.00)
- [ ] Handle **stock splits** — when a `GameStock` reaches or exceeds $2.00, cap at $2.00, double all holders' shares, and reset the price to $1.00 (no carry-over of excess amount)
- [ ] Handle **worthless stocks** — when a `GameStock` drops to $0, all holders' shares are immediately removed and the stock resets to $1.00; play continues as normal
- [ ] Handle **dividends** — the dividend rate matches Die 3 (5%, 10%, or 20% of the stock's current price per share held); dividends only take effect when the `GameStock` price is $1.00 or higher (rolls below $1.00 have no effect)
- [ ] Enforce the classic turn sequence: roll dice -> market moves -> active player may buy/sell -> end turn
- [ ] Only allow `BuyShares` / `SellShares` mutations from the active player after they have rolled
- [ ] Define an `EndTurn` mutation that advances play to the next player
- [ ] Skip turns for players who have dropped out
- [ ] Write unit tests for the `RollDice` mutation, turn sequence enforcement, price changes, splits, worthless stocks, and dividends

### 7. Implement buying and selling

- [ ] Define a `BuyShares` mutation to purchase shares at the `GameStock`'s current price (only allowed for the active player after rolling)
- [ ] Define a `SellShares` mutation to sell shares at the `GameStock`'s current price (only allowed for the active player after rolling)
- [ ] Validate sufficient cash for purchases (return GraphQL user errors on failure)
- [ ] Validate sufficient shares for sales (return GraphQL user errors on failure)
- [ ] Shares are bought/sold in lots of 500 shares
- [ ] A player may make multiple buy/sell transactions before ending their turn
- [ ] Update player cash and holdings after each transaction
- [ ] Log all transactions for game history
- [ ] Add a `transactions` query to fetch game history with pagination
- [ ] Write unit tests for buy/sell mutations, validation errors, and edge cases

### 8. Add Redis caching layer

- [ ] Configure Redis as the Rails cache store (in addition to its existing role for Action Cable)
- [ ] Cache active game state (stock prices, player holdings, turn info) in Redis
- [ ] Implement write-through caching so game state is persisted to Yugabyte on each mutation
- [ ] Invalidate cache on critical events (game over, player join/leave)
- [ ] Use caching for the leaderboard and game listings
- [ ] Write tests to verify cache read/write and persistence

### 9. Plan and set up the client side

- [ ] Choose a JavaScript approach for the frontend (e.g., Stimulus + Turbo, or a lightweight SPA framework)
- [ ] Choose a GraphQL client for queries and mutations (e.g., vanilla `fetch`, `graphql-request`, or Apollo)
- [ ] Set up the Action Cable JavaScript client for receiving GraphQL subscriptions
- [ ] Configure the JS build pipeline (importmap, esbuild, or similar)
- [ ] Create a base layout and asset structure
- [ ] Write a proof-of-concept that fetches data from the `/graphql` endpoint and receives a subscription update in the browser

### 10. Build the game UI

- [ ] Create a game lobby powered by GraphQL queries (`games`, `game`)
- [ ] Display available and active games (show remaining time for in-progress games, player count for waiting games)
- [ ] Add a "Start Game" button visible only to the host (calls `StartGame` mutation) that transitions from the lobby to the game board
- [ ] Build the main game board showing all 6 `GameStock` records and their current prices (via GraphQL query)
- [ ] Display each player's cash balance and holdings
- [ ] Show player presence indicators (online/offline/dropped) via subscriptions
- [ ] Add a dice roll animation triggered by the `RollDice` mutation response
- [ ] Build buy/sell controls that call `BuyShares` / `SellShares` mutations
- [ ] Show a transaction history / activity feed via the `transactions` query
- [ ] Build a net worth leaderboard (cash + portfolio value) with live subscription updates
- [ ] Display a countdown timer on the game board showing remaining play time
- [ ] Add a pause game button for solo players (calls `PauseGame` mutation)
- [ ] Add a game-over screen with final rankings (triggered by `GameEnded` subscription)

### 11. Add real-time updates with GraphQL subscriptions

- [ ] Define a `GameStarted` subscription to notify players in the lobby that the host has started the game
- [ ] Define a `GameStockPriceUpdated` subscription to push per-game price changes to all players in that game
- [ ] Define a `DiceRolled` subscription to broadcast roll results in real time
- [ ] Define a `LeaderboardUpdated` subscription to push net worth changes
- [ ] Define a `TurnChanged` subscription to notify players when it's their turn
- [ ] Define a `PlayerPresenceChanged` subscription for join/leave/rejoin events
- [ ] Define a `GameEnded` subscription to notify all players when the game clock expires (includes final rankings)
- [ ] Configure Action Cable as the transport layer for GraphQL subscriptions
- [ ] Write integration tests for subscription delivery

### 12. Add a real-time chat room

- [ ] Create a `Message` model (user, game, body, timestamp)
- [ ] Define a `SendMessage` GraphQL mutation to post chat messages
- [ ] Define a `MessageReceived` GraphQL subscription for real-time message delivery
- [ ] Build a chat room UI within the game view
- [ ] Build out an emoji functionality so users can use emojis in the chat room
- [ ] Display active players in the chat
- [ ] Write tests for the mutation, subscription, and message delivery

### 13. Add authentication and external access

- [ ] Add user authentication (Devise or a custom solution)
- [ ] Add a `context` hash to `GraphqlController` that resolves the current user from the session/token
- [ ] Guard mutations and queries with authentication checks via GraphQL authorization
- [ ] Implement password-protected access for external users
- [ ] Set up HTTPS / SSL for secure connections
- [ ] Configure the app for external network access (port forwarding, domain, or tunneling)
- [ ] Add role-based access control (admin/host vs. player) enforced at the GraphQL layer
- [ ] Write tests for authentication and authorization in GraphQL context

### 14. Dockerize the app

- [ ] Write a `Dockerfile` for the Rails app
- [ ] Create a `docker-compose.yml` with app, Yugabyte, and Redis services
- [ ] Configure environment variables via `.env` file
- [ ] Test building and running the app in Docker
- [ ] Document Docker setup instructions in this README

### 15. Write the game rules document

- [ ] Create a `RULES.md` file with full game rules and how to play
- [ ] Include commodity descriptions and starting prices
- [ ] Document dice mechanics (3-die system, outcomes)
- [ ] Explain stock splits, worthless stocks, and dividends
- [ ] Cover buying/selling rules and lot sizes
- [ ] Describe game types (solo vs. multiplayer)
- [ ] Add win conditions and scoring
