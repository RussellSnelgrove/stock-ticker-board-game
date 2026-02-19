# Stock Ticker App

A digital version of the classic Stock Ticker board game, built with Ruby on Rails.

## Game Overview

Players buy and sell shares in 6 commodities — **Gold, Silver, Bonds, Grain, Industrial, and Oil**. Each turn, dice rolls determine which stock moves, the direction (Up, Down, or Dividend), and the amount. Stocks can split at the top or become worthless at the bottom. The player with the highest net worth at the end wins.

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

### 3. Build the Stock Ticker data models
- [ ] Create a `Stock` model for the 6 commodities (Gold, Silver, Bonds, Grain, Industrial, Oil)
- [ ] Each stock has a name, current price (range $1.00–$6.00), and status (active/worthless)
- [ ] Create a `Game` model to track game state (status, current turn, start time, end time)
- [ ] Create a `Player` model linked to a User and a Game (starting cash: $5,000)
- [ ] Create a `Holding` model to track shares owned per player per stock
- [ ] Create a `Transaction` model to log all buys, sells, dividends, and splits
- [ ] Create a `DiceRoll` model to record each turn's roll results
- [ ] Add validations and associations between all models
- [ ] Add Sorbet type signatures to all models
- [ ] Seed the database with the 6 default stocks at starting prices
- [ ] Write unit tests for all model validations and associations

### 4. Implement game sessions
- [ ] Create a `Session` model to represent a game session (name, invite code, host, status)
- [ ] Allow a user to create a new session, which starts a new game
- [ ] Allow users to invite friends to a session via a shareable link or code
- [ ] Support **solo games** — a single player can create and play alone
- [ ] Allow solo players to **save and resume** a game later
- [ ] Allow players to **drop out** of a multiplayer game while preserving their state
- [ ] Allow players to **rejoin** a game they previously left
- [ ] Allow players to **join an ongoing game** mid-session
- [ ] Track player presence (online/offline) within a session
- [ ] Write unit tests for session creation, joining, leaving, and rejoining

### 5. Implement the dice and turn mechanics
- [ ] Build a dice rolling service that produces 3 results per turn:
  - **Die 1**: Which stock is affected (Gold, Silver, Bonds, Grain, Industrial, Oil)
  - **Die 2**: Direction (Up, Down, or Dividend)
  - **Die 3**: Amount ($1 or $5 movement)
- [ ] Apply price changes to the affected stock after each roll
- [ ] Handle **stock splits** — when a stock reaches the top ($6.00), all holders' shares double and price resets
- [ ] Handle **worthless stocks** — when a stock drops to $0, all shares are wiped out
- [ ] Handle **dividends** — pay out a percentage of the stock's current value to all holders
- [ ] Enforce turn order so players roll and trade in sequence
- [ ] Skip turns for players who have dropped out
- [ ] Write unit tests for dice rolling, price changes, splits, worthless stocks, and dividends

### 6. Implement buying and selling
- [ ] Allow players to buy shares at the current stock price on their turn
- [ ] Allow players to sell shares at the current stock price on their turn
- [ ] Validate sufficient cash for purchases
- [ ] Validate sufficient shares for sales
- [ ] Shares are bought/sold in lots (e.g., multiples of 100)
- [ ] Update player cash and holdings after each transaction
- [ ] Log all transactions for game history
- [ ] Write unit tests for buy/sell validation, transactions, and edge cases

### 7. Add Memcached caching layer
- [ ] Set up a Memcached instance (local and Docker)
- [ ] Cache active game state (stock prices, player holdings, turn info) in Memcached
- [ ] Periodically write cached game state back to Yugabyte
- [ ] Invalidate cache on critical events (game over, player join/leave)
- [ ] Use caching for the leaderboard and session listings
- [ ] Write tests to verify cache read/write and persistence sync

### 8. Build the game UI
- [ ] Create a game lobby where players can create, join, or resume a session
- [ ] Display available sessions and active games
- [ ] Build the main game board showing all 6 stocks and their current prices
- [ ] Display each player's cash balance and holdings
- [ ] Show player presence indicators (online/offline/dropped)
- [ ] Add a dice roll animation and results display
- [ ] Build buy/sell controls for the active player's turn
- [ ] Show a transaction history / activity feed
- [ ] Build a net worth leaderboard (cash + portfolio value)
- [ ] Add a save game button for solo players
- [ ] Add a game-over screen with final rankings

### 9. Add real-time updates with Action Cable
- [ ] Set up Action Cable for WebSocket support
- [ ] Broadcast stock price changes to all players in real time
- [ ] Broadcast dice roll results to all players
- [ ] Update the leaderboard in real time
- [ ] Notify players when it's their turn
- [ ] Broadcast player join/leave/rejoin events to the session
- [ ] Write integration tests for WebSocket broadcasts

### 10. Add a real-time chat room
- [ ] Create a `Message` model (user, game, body, timestamp)
- [ ] Build a chat room UI within the game view
- [ ] Allow players to send and receive messages in real time via Action Cable
- [ ] Display active players in the chat
- [ ] Write tests for message creation and delivery

### 11. Add authentication and external access
- [ ] Add user authentication (Devise or a custom solution)
- [ ] Implement password-protected access for external users
- [ ] Set up HTTPS / SSL for secure connections
- [ ] Configure the app for external network access (port forwarding, domain, or tunneling)
- [ ] Add role-based access control (admin/host vs. player)
- [ ] Write tests for authentication and authorization

### 12. Dockerize the app
- [ ] Write a `Dockerfile` for the Rails app
- [ ] Create a `docker-compose.yml` with app, Yugabyte, Memcached, and Redis services
- [ ] Configure environment variables via `.env` file
- [ ] Test building and running the app in Docker
- [ ] Document Docker setup instructions in this README

### 13. Write the game rules document
- [ ] Create a `RULES.md` file with full game rules and how to play
- [ ] Include commodity descriptions and starting prices
- [ ] Document dice mechanics (3-die system, outcomes)
- [ ] Explain stock splits, worthless stocks, and dividends
- [ ] Cover buying/selling rules and lot sizes
- [ ] Describe session types (solo vs. multiplayer)
- [ ] Add win conditions and scoring
