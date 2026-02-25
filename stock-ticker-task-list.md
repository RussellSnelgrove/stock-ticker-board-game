# Stock Ticker App

A digital version of the classic Stock Ticker board game, built with Ruby on Rails and a GraphQL API.

## Game Overview

Players buy and sell shares in 6 commodities: **Grain, Industrial, Bonds, Oil, Silver, and Gold**. Each game maintains its own stock prices, starting at $1.00. Each turn, the active player rolls dice **twice**, the market moves after each roll, then the player may buy/sell before ending their turn. Stock prices range from $0.00 to $2.00. Stocks split at $2.00; stocks that drop to $0 are wiped and reset to $1.00. Dividends are only paid when the stock is priced at $1.00 or higher. Each game runs on a countdown timer selected by the host. When the clock reaches zero, the player with the highest net worth wins.

## Constraints

- The app MUST be runnable via `docker-compose up` as the primary development method, using Colima as the container runtime (`brew install colima docker docker-compose`). Do NOT assume services are installed locally.
- All services (database, Redis) MUST be containerized in `docker-compose.yml`.
- Every task that adds infrastructure (database, cache, background jobs) MUST also update `docker-compose.yml` and verify the app works in Docker.
- All tasks MUST be completed. Do not skip tasks or defer them to "later."
- There is NO authentication. Users pick a display name and play immediately. Do NOT use Devise or any auth library.
- A local development mode (without Docker) MUST also be supported for developers who cannot run containers.

## Tasks

### 1. Dockerize the app and scaffold Rails

- [ ] Install Colima, Docker CLI, and Docker Compose via Homebrew (`brew install colima docker docker-compose`)
- [ ] Write a `Dockerfile.dev` for the Rails development environment
- [ ] Create a `docker-compose.yml` with app, PostgreSQL (Yugabyte in production, PostgreSQL in Docker for local dev compatibility), and Redis services. The PostgreSQL health check MUST specify the database name: `pg_isready -U stock_ticker -d stock_ticker_development` (without `-d`, it defaults to a database named after the user which won't exist).
- [ ] Configure environment variables so the app reads `DATABASE_URL` and `REDIS_URL` from the Docker environment
- [ ] Install the latest stable version of Rails (`gem install rails`)
- [ ] Scaffold a new Rails project (`rails new stock-ticker --database=postgresql`) inside the Docker container
- [ ] Verify the app runs via `docker-compose up` and is accessible at `http://localhost:3000`
- [ ] Configure `database.yml` and `cable.yml` to use environment variables (Docker passes them in; local dev falls back to defaults)
- [ ] Create a `.dockerignore` that excludes `.ruby-version`, `tmp/`, `log/`, `node_modules/`, `.git/`
- [ ] Delete the `.ruby-version` file that Rails generates (it conflicts with chruby/rbenv on the host and is not needed — the Ruby version is pinned in `Dockerfile.dev`)
- [ ] Create a `bin/docker-setup` script that runs `db:create db:migrate db:seed`
- [ ] Document local development mode (without Docker) using locally installed Ruby, PostgreSQL, and Redis
- [ ] Set up a Git repository and make an initial commit

### 2. Set up GraphQL

- [ ] Add the `graphql-ruby` gem to the Gemfile
- [ ] Run the GraphQL generator (`rails generate graphql:install`)
- [ ] Configure the `GraphqlController` with a single `/graphql` endpoint
- [ ] Set up the base `StockTickerSchema` with query, mutation, and subscription root types
- [ ] Configure Action Cable with Redis as the GraphQL subscriptions transport
- [ ] Add GraphiQL or GraphQL Playground for development (via `graphiql-rails` gem)
- [ ] Write a smoke test that queries the GraphQL endpoint successfully

### 3. Add Sorbet for type safety

- [ ] Install the `sorbet` and `tapioca` gems
- [ ] Run `tapioca init` to generate RBI files (including RBIs for `graphql-ruby`)
- [ ] Configure Sorbet strictness levels per file
- [ ] Add typed signatures (`sig`) to the GraphQL schema, controller, models, and services as they are built
- [ ] Integrate Sorbet type checking into the development workflow

### 4. Build the Stock Ticker data models

- [ ] Create a `User` model with just a `display_name` field (no authentication — users pick a name and play immediately)
- [ ] Create a `Stock` model as a static lookup for the 6 commodities in this exact order: Grain, Industrial, Bonds, Oil, Silver, Gold
- [ ] Create a `GameStock` model (belongs to `Game` and `Stock`) to track each stock's price within a game
  - Fields: `current_price` (range $0.00-$2.00)
  - Each game gets its own set of 6 `GameStock` records initialized at $1.00
- [ ] Create a `Game` model to represent a game session and its state:
  - Fields: `name`, `invite_code`, `host` (belongs to `User`), `status`, `current_turn`, `duration`, `starts_at`, `ends_at`, `remaining_time`
  - Status state machine: `waiting` (lobby, accepting players) -> `in_progress` (clock running) -> `paused` (solo only) -> `completed` (timer expired)
  - Only mutations valid for the current status should be accepted (e.g., no rolling in "waiting", no trading in "completed")
  - Expose `rolls_remaining_this_turn` as a computed field so the client can sync roll state
- [ ] Create a `Player` model linked to a User and a Game
  - Fields: `cash` (starting at $5,000), `status` (active/dropped), `turn_position` (integer, set by join order)
- [ ] Create a `Holding` model to track shares owned per player per `GameStock`
  - Fields: `player_id`, `game_stock_id`, `quantity` (integer, multiples of 500)
- [ ] Create a `GameTransaction` model to log all buys, sells, dividends, and splits (use `GameTransaction` not `Transaction` to avoid Rails reserved name)
  - Fields: `player_id`, `game_stock_id`, `transaction_type` (buy/sell/dividend/split/worthless_reset), `quantity`, `price_at_time`, `total_amount`, `turn_number`
- [ ] Create a `DiceRoll` model to record each turn's roll results
  - Fields: `game_id`, `player_id`, `turn_number`, `stock_rolled` (references `Stock`), `direction` (up/down/dividend), `amount` ($0.05/$0.10/$0.20)
- [ ] Create a `Message` model for in-game chat
  - Fields: `user_id`, `game_id`, `body` (max 200 chars)
- [ ] Add validations and associations between all models
- [ ] Add Sorbet type signatures to all models
- [ ] Define GraphQL types for each model (`GameStockType`, `GameType`, `PlayerType`, `HoldingType`, `GameTransactionType`, `DiceRollType`, `MessageType`)
- [ ] Seed the database with the 6 static `Stock` records in order: Grain, Industrial, Bonds, Oil, Silver, Gold
- [ ] Write unit tests for all model validations and associations

### 5. Implement game lifecycle

- [ ] Define a `CreateGame` mutation (accepts a `duration` in minutes, generates an invite code, initializes 6 `GameStock` records at $1.00, sets status to "waiting" — clock does **not** start yet)
- [ ] Define a `StartGame` mutation (host-only) to transition the game from "waiting" to "in_progress", compute `ends_at` from the duration, and schedule the game clock expiry job
- [ ] Define a `JoinGame` mutation to join via invite code (if the player was previously in the game, restore their state; otherwise create a new `Player` record with $5,000 cash and 0 shares)
- [ ] Define a `LeaveGame` mutation to drop out while preserving state
- [ ] Add a `games` query to list available and active games
- [ ] Add a `game` query to fetch a single game by ID or invite code (includes `ends_at`, remaining time, and `rollsRemainingThisTurn`)
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

- [ ] Build a dice rolling service that produces 3 results per roll (all dice are **uniformly weighted** — each outcome is equally likely):
  - **Die 1**: Which stock is affected (1/6 each: Grain, Industrial, Bonds, Oil, Silver, Gold)
  - **Die 2**: Direction (1/3 each: Up, Down, or Dividend)
  - **Die 3**: Amount (1/3 each: $0.05, $0.10 or $0.20 movement)
- [ ] Each player rolls **twice per turn** before trading (ROLLS_PER_TURN = 2). The `RollDice` mutation tracks rolls per turn and returns `rollsRemaining`.
- [ ] Define a `RollDice` mutation that invokes the dice service and returns the roll result plus `rollsRemaining`
- [ ] Apply price changes to the affected `GameStock` after each roll
- [ ] Share supply is **unlimited** — players may buy as many shares as they can afford
- [ ] **Price floor**: $0.00 is the absolute minimum; any roll that would take a stock below $0 triggers the worthless behavior (wipe shares, reset to $1.00)
- [ ] Handle **stock splits** — when a `GameStock` reaches or exceeds $2.00, cap at $2.00, double all holders' shares, and reset the price to $1.00 (no carry-over of excess amount)
- [ ] Handle **worthless stocks** — when a `GameStock` drops to $0, all holders' shares are immediately removed and the stock resets to $1.00; play continues as normal
- [ ] Handle **dividends** — the dividend rate matches Die 3 (5%, 10%, or 20% of the stock's current price per share held); dividends only take effect when the `GameStock` price is $1.00 or higher (rolls below $1.00 have no effect)
- [ ] Enforce the classic turn sequence: roll dice twice -> market moves after each roll -> active player may buy/sell -> end turn
- [ ] Only allow `BuyShares` / `SellShares` mutations from the active player after they have completed both rolls
- [ ] Define an `EndTurn` mutation that advances play to the next player (requires both rolls completed)
- [ ] Skip turns for players who have dropped out
- [ ] Write unit tests for the `RollDice` mutation, turn sequence enforcement, price changes, splits, worthless stocks, and dividends

### 7. Implement buying and selling

- [ ] Define a `BuyShares` mutation to purchase shares at the `GameStock`'s current price (only allowed for the active player after completing both rolls)
- [ ] Define a `SellShares` mutation to sell shares at the `GameStock`'s current price (only allowed for the active player after completing both rolls)
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
- [ ] Implement write-through caching so game state is persisted to the database on each mutation
- [ ] Invalidate cache on critical events (game over, player join/leave)
- [ ] Use caching for the leaderboard and game listings
- [ ] Write tests to verify cache read/write and persistence

### 9. Set up the client-side design system

#### 9a. Tooling

- [ ] Use vanilla JS with `fetch` for GraphQL queries/mutations and importmap for module loading. IMPORTANT: importmap requires bare specifiers in imports (`import GameClient from "game_client"`), NOT relative paths (`"./game_client"`). Pin each module in `config/importmap.rb`.
- [ ] Set up the Action Cable JavaScript client for receiving GraphQL subscriptions
- [ ] Write a proof-of-concept that fetches data from the `/graphql` endpoint and receives a subscription update in the browser

#### 9b. Theme and design language

Dark theme with a financial terminal aesthetic. Dark gray background (`#0F172A`), bright accent colors, high-contrast text (`#E2E8F0`).

- [ ] Load fonts from Google Fonts in the layout `<head>`:
  - **Primary**: Inter (weights: 400, 500, 600, 700, 800, 900) — all UI text
  - **Monospace**: JetBrains Mono (weights: 400, 500, 600, 700) — prices, numbers, dice values

```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet">
```

#### 9c. Color palette

- [ ] Implement stock colors as constants (each commodity has a fixed color throughout):

| Stock      | Symbol | Color   |
| ---------- | ------ | ------- |
| Grain      | GRN    | #D97706 |
| Industrial | IND    | #EF4444 |
| Bonds      | BNDS   | #3B82F6 |
| Oil        | OIL    | #10B981 |
| Silver     | SLVR   | #94A3B8 |
| Gold       | GOLD   | #F59E0B |

- [ ] Implement player colors (assigned by join order, cycle if more than 4):

| Position | Color   |
| -------- | ------- |
| 1        | #3B82F6 |
| 2        | #EF4444 |
| 3        | #22C55E |
| 4        | #F59E0B |

- [ ] Implement semantic colors:
  - Up/gain: `#22C55E` | Down/loss: `#EF4444` | Dividend: `#F59E0B` | Split: `#3B82F6` | Crash: `#EF4444` (brighter flash)
  - Buy buttons: green tint | Sell buttons: red tint

#### 9d. Button styles

- [ ] Create button CSS classes:
  - `btn-primary`: Main CTA (Roll Dice, Start Game, Done Trading). Bold, filled background.
  - `btn-danger`: Destructive action (End Game). Red accent.
  - `btn-ghost`: Secondary action (Add Player, Leave Game). Transparent with border.
  - `btn-small`: Compact variant for header actions.
  - `btn-large`: Full-width variant for primary screen actions.
  - `quick-btn`: Small inline pill-shaped buttons for trading. Subtypes: `quick-buy` (green tint), `quick-sell` (red tint), `quick-max` (italic).

#### 9e. Number formatting

- [ ] Implement consistent formatting helpers:
  - **Prices** (stock prices, amounts): `$X.XX`, always 2 decimal places. Stored as integer cents. Display via `(cents / 100).toFixed(2)`.
  - **Money** (cash, net worth, costs): `$X,XXX` with thousand separators, no decimals. Use `toLocaleString('en-US')`.
  - **Shares**: Thousand separators (e.g., "1,500 shares").

### 10. Build the game UI

The app uses a screen-switching pattern. Only one `.screen` is visible at a time (toggled via the `.active` class). There are 5 screens.

#### 10a. Screen: Username Entry

No authentication — users pick a name and play immediately.

- [ ] Centered card layout with the app logo (SVG bar chart: 4 colored bars — green, blue, amber, red)
- [ ] Title "Stock Ticker" with gradient text (`linear-gradient(135deg, #F59E0B, #EF4444)`)
- [ ] Single text input for display name (placeholder: "Your name", maxlength: 20, autofocus)
- [ ] "Play" button submits a POST to `/join` which creates/finds a `User` and stores `user_id` in the Rails session
- [ ] On success, redirects to the lobby (home screen)
- [ ] CSS class: `username-form`

#### 10b. Screen: Home / Game Lobby

Shown after entering a username. Centered card layout.

- [ ] App logo and title (reuse from username screen)
- [ ] Subtitle: "Playing as **[display_name]**"
- [ ] **Create Game form**: game name input (maxlength: 30), duration select (15/30/60/90 min), "Create Game" button. Calls `CreateGame` mutation.
- [ ] **Join by Code form**: text input (maxlength: 6, uppercase monospace, letter-spacing), "Join" button. Calls `JoinGame` mutation.
- [ ] **Open Games list**: rows showing game name, player count, duration, host name, and a "Join" button. Populated via `games` GraphQL query.
- [ ] If no open games: "No open games yet. Create one!" message.
- [ ] CSS classes: `setup-container`, `lobby-actions`, `create-game-form`, `join-game-form`, `game-list-section`, `game-list`, `game-list-item`, `game-list-empty`

#### 10c. Screen: Waiting Room

Shown after creating or joining a game in "waiting" status. Centered card layout.

- [ ] Game name as heading
- [ ] Invite code displayed prominently (large monospace text `invite-code-value`, with "Copy" button using `navigator.clipboard.writeText`)
- [ ] Duration badge (e.g., "60 min")
- [ ] Player list in join order: numbered 1, 2, 3... with a colored dot using their player color. Host labeled "(host)".
- [ ] "Start Game" button: only visible to the host, large primary button. Calls `StartGame` mutation.
- [ ] "Leave Game" button for non-host players. Calls `LeaveGame` mutation.
- [ ] Subscribe to `PlayerPresenceChanged` to update the player list in real time.
- [ ] On `GameStarted` subscription event, transition all clients to the game screen.
- [ ] CSS classes: `invite-code-display`, `invite-code-label`, `invite-code-value`, `duration-badge`, `waiting-player-list`, `waiting-player-item`, `waiting-player-dot`, `waiting-player-number`, `waiting-player-name`, `waiting-player-host`

#### 10d. Screen: Game Board

The core gameplay screen. Uses a **three-column layout**: Game Log (left, 260px) | Game Board (center, flexible) | Sidebar (right, 300px).

```css
.game-layout {
  display: grid;
  grid-template-columns: 260px 1fr 300px;
  gap: 0;
  min-height: calc(100vh - 140px);
}
```

**Turn flow**: Roll 1 of 2 → Roll 2 of 2 → Trading phase (cards expand) → Done Trading → next player.

##### Game Header

- [ ] Top bar with: game title (gradient text), turn number badge (`round-badge`), countdown timer (`clock-badge`), pause button (solo only)
- [ ] Clock turns red (`warning` class) under 5 min, pulses (`critical` class + CSS `pulse` animation) under 1 min
- [ ] Update clock every second from `game.endsAt`

##### Event Ticker

- [ ] Horizontally scrolling marquee strip below the header
- [ ] Event items colored by type: `.up` (green), `.down` (red), `.dividend` (amber), `.split` (blue), `.crash` (red bold), `.trade` (neutral)
- [ ] Content duplicated (`items + items`) for seamless CSS animation loop (`ticker-scroll 30s linear infinite`)
- [ ] Maximum 50 events stored, most recent 20 displayed

##### Phase Banner

- [ ] Full-width colored bar below the event ticker
- [ ] Rolling phase: blue tint (`phase-rolling`), shows "Roll 1 of 2" or "Roll 2 of 2" + active player name in their color
- [ ] Trading phase: green tint (`phase-trading`), shows "Buy & Sell" + active player name
- [ ] When not your turn: shows whose turn it is

##### Game Log (left sidebar)

- [ ] **Last roll section**: Three dice values as small colored badges — stock symbol in its commodity color, direction colored green/red/amber (`die-up`, `die-down`, `die-dividend`), amount in neutral. Below: outcome message colored by event type.
- [ ] **Net worth tracker**: All players ranked by net worth descending. Each entry shows:
  - Player name (in their player color if it's you)
  - Current net worth in monospace (`nw-current`)
  - Change since last roll: green `+$X` (`nw-change positive`), red `-$X` (`nw-change negative`), gray dash (`nw-change neutral`)
  - Colored bar below proportional to max net worth (`nw-bar`)
- [ ] Client MUST snapshot all players' net worth before each roll, then show the diff after
- [ ] CSS classes: `game-log`, `log-panel`, `last-roll`, `last-roll-result`, `last-roll-dice`, `last-roll-die`, `last-roll-message`, `net-worth-tracker`, `nw-entry`, `nw-name`, `nw-values`, `nw-current`, `nw-change`, `nw-bar`

##### Stock Board (center)

- [ ] 1x6 horizontal grid of **static** stock cards in fixed order: Grain, Industrial, Bonds, Oil, Silver, Gold

```css
.stock-board { display: grid; grid-template-columns: repeat(6, 1fr); gap: 0.75rem; }
```

- [ ] Cards are created ONCE via `initStockBoard()` when entering the game. DOM positions NEVER change. Only text content (price, change) is updated in place via `renderStockBoard()`. This prevents cards from jumping or reordering.
- [ ] Each card contains: `.stock-name` (in stock color), `.stock-price` (monospace), `.stock-change`, `.stock-card-trade-slot` (empty container for trade controls)
- [ ] `stock-change` shows the change from the **last time this stock's price changed** (previous roll that affected it), NOT overall from $1.00. Client tracks each stock's previous price.
- [ ] **Flash animations**: When a stock is affected by a roll, the card flashes for 600ms:
  - `flash-up`: green glow | `flash-down`: red glow | `flash-dividend`: amber glow
  - Triggered by adding class, forcing reflow (`void card.offsetWidth`), then removing after timeout

##### Trading Phase (inline on stock cards)

- [ ] When `rollsRemaining` reaches 0, each card gains `.trading` class and the `.stock-card-trade-slot` is populated with buy/sell controls. Cards animate taller (CSS transition on `max-height`).
- [ ] Trade controls per card: holdings info (`trade-holdings`), buy row, sell row
- [ ] Quick lot buttons: presets `[1, 5, 10, 25]`. Show only presets the player can afford (buy) or owns (sell). Add "Max(N)" / "All(N)" if the max isn't a preset. Show em-dash if none available.
- [ ] Buttons use event delegation on `#stock-board` for click handling
- [ ] "Done Trading" button in a separate `trade-actions` container below the board. Calls `EndTurn` mutation.
- [ ] When not your turn or during rolling: cards show market data only, no trade controls.

##### Dice Area (center, below stock board)

- [ ] Visible during rolling phase, hidden during trading
- [ ] Three dice: Stock (`.die#die-stock`), Action (`.die#die-direction`), Amount (`.die#die-amount`). Each has a `.die-label` and `.die-value`.
- [ ] **Roll animation**: Add `.rolling` class (CSS shake). 15 ticks at 80ms — random values cycle. After animation, set final values:
  - Stock die: commodity symbol, border color = stock color
  - Direction die: "UP ▲" / "DOWN ▼" / "DIV ★" with `result-up` / `result-down` / `result-dividend` class
  - Amount die: cent value (e.g., "10¢")
- [ ] Dice message below: describes outcome, colored by type
- [ ] Roll button text: "Roll Dice (1 of 2)" → "Roll Dice (2 of 2)". After roll 2, dice area hides.
- [ ] `rollsRemaining` synced from server via `rollsRemainingThisTurn` field to prevent desync. Client calls `syncPhaseFromServer()` after every game state update.

##### Right Sidebar: Your Portfolio

- [ ] Panel with border color = your player color
- [ ] Header: your name + phase label ("Rolling (1/2)", "Trading", "Watching")
- [ ] Stats: Cash (green), Net Worth — in `stat-box` containers
- [ ] Holdings list: stock symbol (in color), share count, current value. "No stocks held" if empty.

##### Right Sidebar: Scoreboard

- [ ] All players ranked by net worth descending
- [ ] Each entry: rank number, player name (active player highlighted with `.active` class in their color), net worth in monospace
- [ ] Bar chart: width proportional to max net worth, colored by player color
- [ ] In multiplayer: online/offline dot next to each name

##### Right Sidebar: Chat

- [ ] Message list (scroll, newest at bottom, auto-scroll on new)
- [ ] Author name in player color + message text
- [ ] Input field (maxlength: 200) + "Send" button. Enter key also sends.
- [ ] Sends via `SendMessage` mutation. Receives via `MessageReceived` subscription.

##### Toast Notifications

- [ ] Floating notification for splits, crashes, dividends
- [ ] Created dynamically, appended to `<body>`. Types: `split-toast`, `crash-toast`, `dividend-toast`.
- [ ] Slide-in animation (`.show` class), auto-dismiss after 2500ms (300ms fade-out).
- [ ] Only one toast at a time.

#### 10e. Screen: Game Over / Results

- [ ] Trophy emoji, "Game Over" heading
- [ ] Players sorted by final net worth. Rank 1/2/3 use medal emojis, rank 4+ numeric.
- [ ] Each entry: player name (in their color), profit/loss amount and percentage vs. starting $5,000, final net worth.
- [ ] "Play Again" button (returns to lobby). In multiplayer, also "Back to Lobby".
- [ ] Triggered by `GameEnded` subscription.

#### 10f. Responsive layout

- [ ] **Desktop (1200px+)**: Three-column layout. 1x6 stock card row.
- [ ] **Tablet (768-1199px)**: Single column. Game log above board. Sidebar below. Stock board 3x2 grid.
- [ ] **Mobile (<768px)**: Single column. Stock board 2x3 grid. Chat in slide-out drawer. Game log above board.

#### 10g. Render cycle

The `render()` function calls all of these on every state change:

1. `initStockBoard()` — Creates 6 static card DOM elements once (Grain, Industrial, Bonds, Oil, Silver, Gold)
2. `renderStockBoard()` — Updates price/change text inside existing cards. Injects trade controls during trading. Never recreates cards.
3. `renderPhaseBanner()` — Phase name, active player, roll progress
4. `renderDiceArea()` — Show/hide dice and roll button based on phase
5. `renderPlayerPanel()` — Your cash, net worth, portfolio
6. `renderScoreboard()` — All players ranked
7. `renderEventTicker()` — Scrolling event feed
8. `renderRoundDisplay()` — Turn number badge
9. `renderGameLog()` — Left sidebar: last roll + net worth tracker

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

- [ ] Define a `SendMessage` GraphQL mutation to post chat messages
- [ ] Define a `MessageReceived` GraphQL subscription for real-time message delivery
- [ ] Build a chat room UI in the right sidebar within the game view
- [ ] Build out an emoji functionality so users can use emojis in the chat room
- [ ] Display active players in the chat
- [ ] Write tests for the mutation, subscription, and message delivery

### 13. Write the game rules document

- [ ] Create a `RULES.md` file with full game rules and how to play
- [ ] Include commodity descriptions and starting prices
- [ ] Document dice mechanics (3-die system, outcomes, 2 rolls per turn)
- [ ] Explain stock splits, worthless stocks, and dividends
- [ ] Cover buying/selling rules and lot sizes
- [ ] Describe game types (solo vs. multiplayer)
- [ ] Add win conditions and scoring
