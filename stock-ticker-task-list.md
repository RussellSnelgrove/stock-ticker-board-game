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
- Do NOT use rbenv or rvm. For local dev without Docker, use chruby or Homebrew Ruby (`brew install ruby`).

## Tasks

### 1. Dockerize the app and scaffold Rails

- [x] Create a develop branch for developing
  > **Why**: Keeps `main` stable and production-ready. All work branches off `develop` so we can test before merging.

- [x] Install Colima, Docker CLI, and Docker Compose via Homebrew (`brew install colima docker docker-compose`)
  > **Why**: Colima is a lightweight container runtime for macOS that doesn't require Docker Desktop (which has licensing restrictions). It runs containers via a Linux VM.

- [x] Write a `Dockerfile.dev` for the Rails development environment
  > **Why**: Pins Ruby 3.3.7 and all system dependencies so every developer gets an identical environment regardless of what's installed on their Mac. Eliminates "works on my machine" issues.

- [x] Create a `docker-compose.yml` with app, PostgreSQL (Yugabyte in production, PostgreSQL in Docker for local dev compatibility), and Redis services. The PostgreSQL health check MUST specify the database name: `pg_isready -U stock_ticker -d stock_ticker_development` (without `-d`, it defaults to a database named after the user which won't exist).
  > **Why**: Defines all three services (app, database, Redis) as a single unit so `docker-compose up` starts everything together. The `-d` flag on the health check is critical — without it the check always fails because it looks for a database named `stock_ticker` which doesn't exist.

- [x] Configure environment variables so the app reads `DATABASE_URL` and `REDIS_URL` from the Docker environment
  > **Why**: Externalising connection strings means the same codebase works in Docker, locally, and in production without changing any files — just the environment variables change.

- [x] Install Rails 8.1.2 on Ruby 3.3.7: `gem install rails -v 8.1.2` (pin these exact versions in `Dockerfile.dev` and `Gemfile`)
  > **Why**: Pinning exact versions ensures reproducible builds. Anyone building the image at any time gets the same Rails and Ruby versions we developed against.

- [x] Bootstrap sequence: write `Dockerfile.dev` and `docker-compose.yml` on the host first → `docker-compose build` → `docker-compose run --rm app rails new . --database=postgresql --force` to scaffold Rails into the current directory inside the container
  > **Why**: Solves the chicken-and-egg problem — you can't run `rails new` locally if you don't have Ruby installed, but you can't build a Docker image without a Gemfile. Writing the Docker files first lets the container generate the Rails scaffold.

- [x] Scaffold a new Rails project (`rails new stock-ticker --database=postgresql`) inside the Docker container
  > **Why**: Generates the full Rails directory structure, Gemfile, config files, and boilerplate inside the container so the Ruby version is guaranteed correct.

- [x] Set Active Job queue adapter to `:async` in `config/environments/development.rb` (Solid Queue is removed; `:async` runs jobs in-process without a separate worker)
  > **Why**: We removed Solid Queue (which requires a separate worker process and a database-backed queue). The `:async` adapter runs background jobs in threads inside the same Puma process — no extra infrastructure needed in dev. `GameClockExpiryJob` will fire correctly without any additional setup.

- [x] Remove the Rails 8.1 Solid gems that conflict with Redis: remove `solid_cache`, `solid_queue`, and `solid_cable` from the Gemfile; delete `config/cache.yml`, `config/queue.yml`, `config/recurring.yml`, `db/cache_schema.rb`, `db/queue_schema.rb`, and `db/cable_schema.rb`; remove the Solid Queue Puma plugin from `config/puma.rb`; replace Solid references in `config/environments/production.rb` with Redis-backed equivalents
  > **Why**: Rails 8.1 ships with Solid gems that use the database for caching, queuing, and Action Cable. We're using Redis for all of these instead — it's faster, more appropriate for real-time features, and avoids running multiple database backends.

- [x] Verify the app runs via `docker-compose up` and is accessible at `http://localhost:3000`
  > **Why**: Confirms all the Docker configuration, environment variables, and Rails setup work together end-to-end before moving on to building features.

- [x] Configure `database.yml` and `cable.yml` to use environment variables (Docker passes them in; local dev falls back to defaults)
  > **Why**: Rails needs to know how to connect to PostgreSQL and Redis. Reading from environment variables means Docker injects the containerised connection strings automatically, while local dev without Docker falls back to `localhost` defaults.

- [x] Set `config.hosts.clear` and `config.action_cable.disable_request_forgery_protection = true` in `config/environments/development.rb` so WebSocket connections and multiplayer on a local network or via tunnels work from Docker clients
  > **Why**: Rails 6+ blocks requests from unknown hosts by default. When running in Docker, the app is accessed via `localhost` from outside the container, and WebSocket connections come from browser origins that don't match the container's hostname. These settings disable those checks in development only.

- [x] Create a `.dockerignore` that excludes `.ruby-version`, `tmp/`, `log/`, `node_modules/`, `.git/`
  > **Why**: Prevents unnecessary files from being sent to Docker during builds. Excluding `tmp/`, `log/`, and `.git/` keeps the build context small and fast, and avoids accidentally copying dev state into the image.

- [x] Create a `bin/docker-setup` script that runs `db:create db:migrate db:seed`
  > **Why**: Gives new developers a single command to initialise the database inside Docker on first run, rather than having to know the individual Rails commands.

- [x] Document local development mode (without Docker) using locally installed Ruby, PostgreSQL, and Redis
  > **Why**: Some developers can't run Docker (e.g., device policy restrictions). The README must explain how to set up the app locally using Homebrew Ruby, PostgreSQL, and Redis so those developers aren't blocked.

- [x] Set up a Git repository and make an initial commit
  > **Why**: Establishes version control from the start so all changes are tracked and the project history is preserved.

### 2. Set up GraphQL

- [x] Add the `graphql-ruby` gem to the Gemfile
  > **Why**: `graphql-ruby` is the standard Ruby implementation of the GraphQL spec. It provides the schema definition DSL, type system, mutation/query/subscription support, and Action Cable integration we need.

- [x] Run the GraphQL generator (`rails generate graphql:install`)
  > **Why**: Scaffolds the base schema file, `GraphqlController`, base types, and the channel for subscriptions so we don't have to write boilerplate from scratch.

- [x] Configure the `GraphqlController` with a single `/graphql` endpoint
  > **Why**: GraphQL uses a single endpoint for all operations (queries, mutations, subscriptions) unlike REST's multiple endpoints. This simplifies routing and keeps all API logic in one place.

- [x] Set up the base `StockTickerSchema` with query, mutation, and subscription root types
  > **Why**: The schema is the entry point for all GraphQL operations. Defining query, mutation, and subscription roots upfront establishes the structure that all future types and resolvers hang off.

- [x] Configure Action Cable with Redis as the GraphQL subscriptions transport
  > **Why**: GraphQL subscriptions require a pub/sub backend to push updates to connected clients. Action Cable handles the WebSocket connections, and Redis is the message bus that allows multiple server processes to broadcast to all subscribers.

- [x] Add GraphiQL or GraphQL Playground for development (via `graphiql-rails` gem)
  > **Why**: Provides an in-browser IDE for exploring and testing the GraphQL API during development. Makes it easy to write queries, inspect the schema, and debug without a separate client.

- [x] Write a smoke test that queries the GraphQL endpoint successfully
  > **Why**: Verifies the GraphQL endpoint is wired up correctly and returns a valid response. Catches configuration issues early before any real resolvers are built.

### 3. Add Sorbet for type safety

- [x] Install the `sorbet` and `tapioca` gems
  > **Why**: Sorbet adds static type checking to Ruby. `tapioca` generates the RBI (Ruby Interface) files that teach Sorbet about gems and Rails internals. Together they catch type errors at development time rather than in production.

- [x] Run `tapioca init` to generate RBI files (including RBIs for `graphql-ruby`)
  > **Why**: Without RBI files, Sorbet doesn't know the types of methods provided by gems like `graphql-ruby` and Rails, so it can't type-check code that uses them.

- [x] Configure Sorbet strictness levels per file
  > **Why**: Sorbet has graduated strictness levels (`# typed: false`, `ignore`, `true`, `strict`). Starting at `false` for generated files and `true` for new code lets us adopt Sorbet incrementally without having to type every existing file at once.

- [x] Add typed signatures (`sig`) to the GraphQL schema, controller, models, and services as they are built
  > **Why**: Type signatures document the expected inputs and outputs of methods and let Sorbet verify them statically. Most valuable on services and models where bugs from wrong types are hardest to catch.

- [x] Integrate Sorbet type checking into the development workflow
  > **Why**: Running `srb tc` (Sorbet type check) should be part of the CI pipeline and local dev so type errors are caught before they reach production.

### 4. Build the Stock Ticker data models

- [x] Create a `User` model with just a `display_name` field (no authentication — users pick a name and play immediately)
  > **Why**: The game has no login — users just pick a name. A lightweight `User` record ties a session to a display name and persists it across page reloads without requiring auth infrastructure.

- [x] Create a `Stock` model as a static lookup for the 6 commodities in this exact order: Grain, Industrial, Bonds, Oil, Silver, Gold
  > **Why**: The 6 commodities are fixed and universal — they never change between games. A seeded lookup table is the right model for static reference data. Fixed order matters for consistent UI rendering.

- [x] Create a `GameStock` model (belongs to `Game` and `Stock`) to track each stock's price within a game
  - Fields: `current_price` (stored as integer cents; 100 = $1.00, range 0–200)
  - Each game gets its own set of 6 `GameStock` records initialized at $1.00
  > **Why**: Each game has independent stock prices — a split in one game doesn't affect another. `GameStock` is the join between a game and a commodity that carries the per-game price state. Storing price as integer cents avoids floating-point rounding errors.

- [x] Create a `Game` model to represent a game session and its state:
  - Fields: `name`, `invite_code` (6-character uppercase alphanumeric, generated via `SecureRandom.alphanumeric(6).upcase`), `host` (belongs to `User`), `status`, `current_turn`, `duration`, `starts_at`, `ends_at`, `remaining_time`
  - Status state machine: `waiting` (lobby, accepting players) -> `in_progress` (clock running) -> `paused` (solo only) -> `completed` (timer expired)
  - Only mutations valid for the current status should be accepted (e.g., no rolling in "waiting", no trading in "completed")
  - Add `rolls_remaining_this_turn` as an integer column (default: `ROLLS_PER_TURN = 2`); decremented by `RollDice`, reset to 2 by `EndTurn`
  - Expose `active_player` as a computed method: `players.active.order(:turn_position).offset(current_turn % active_player_count).first`
  > **Why**: `Game` is the central model everything else belongs to. The status state machine enforces valid transitions and prevents illegal actions (e.g., rolling after the game ends). `rolls_remaining_this_turn` is stored on the server — not tracked client-side — to prevent desync. The invite code lets players join by sharing a short code instead of a long URL.

- [x] Create a `Player` model linked to a User and a Game
  - Fields: `cash` (stored as integer cents; 500_000 = $5,000 starting balance), `status` (active/dropped), `turn_position` (integer, set by join order)
  > **Why**: A `Player` is the join between a `User` and a `Game`, carrying per-game state (cash, turn position, active/dropped). Separating `User` from `Player` allows the same user to play in multiple games simultaneously.

- [ ] Create a `Holding` model to track shares owned per player per `GameStock`
  - Fields: `player_id`, `game_stock_id`, `quantity` (integer, multiples of 500)
  > **Why**: Holdings are the core portfolio data. A separate model (rather than embedding in `Player`) lets us query "who holds what" efficiently, which is needed for splits, worthless resets, and dividend payouts.

- [x] Create a `GameTransaction` model to log all buys, sells, dividends, and splits (use `GameTransaction` not `Transaction` to avoid Rails reserved name)
  - Fields: `player_id`, `game_stock_id`, `transaction_type` (buy/sell/dividend/split/worthless_reset), `quantity`, `price_at_time`, `total_amount`, `turn_number`
  > **Why**: A full audit log of every financial event in the game. Powers the game history view and makes it possible to reconstruct a player's net worth at any point. `Transaction` is a reserved name in Rails/ActiveRecord so we use `GameTransaction`.

- [x] Create a `DiceRoll` model to record each turn's roll results
  - Fields: `game_id`, `player_id`, `turn_number`, `stock_rolled` (references `Stock`), `direction` (up/down/dividend), `amount` (stored as integer cents; 5 = $0.05, 10 = $0.10, 20 = $0.20)
  > **Why**: Persisting roll results means late-joining players and page refreshes can reconstruct the game log. Also useful for verifying the dice are truly random and for replaying game history.

- [x] Create a `Message` model for in-game chat
  - Fields: `user_id`, `game_id`, `body` (max 200 chars)
  > **Why**: Persisting chat messages means players who reconnect can see recent chat history rather than a blank room. The 200-char limit keeps messages readable.

- [x] Configure `ApplicationCable::Connection` to authenticate via the Rails session cookie: read `request.session[:user_id]`, look up the `User`, and set `current_user` on the connection (reject connections with no session or unknown user)
  > **Why**: Action Cable WebSocket connections need to know who is connecting so subscriptions can be scoped to the right game and player. Reading the Rails session cookie (same one used for HTTP requests) avoids duplicating auth logic.

- [x] Add validations and associations between all models
  > **Why**: Database-level constraints (via migrations) and model-level validations (via ActiveRecord) together ensure data integrity. Without them, bugs can silently corrupt game state.

- [x] Add Sorbet type signatures to all models
  > **Why**: Models are used everywhere — having typed signatures catches wrong argument types early and documents what each method expects.

- [x] Define GraphQL types for each model (`GameStockType`, `GameType`, `PlayerType`, `HoldingType`, `GameTransactionType`, `DiceRollType`, `MessageType`)
  > **Why**: GraphQL types define the shape of the API — what fields clients can query. Each model needs a corresponding type so the frontend can access its data.

- [x] Seed the database with the 6 static `Stock` records in order: Grain, Industrial, Bonds, Oil, Silver, Gold
  > **Why**: The 6 commodities must exist before any game can be created. Seeding them in `db/seeds.rb` ensures they're present in every environment (development, test, production) after `db:seed` runs.

- [x] Write unit tests for all model validations and associations
  > **Why**: Models are the foundation of the app. Tests here catch broken validations, missing associations, and constraint violations before they cause runtime errors.

### 5. Implement game lifecycle

- [x] Define a `CreateGame` mutation (accepts a `duration` in minutes — **presets only**: 15, 30, 60, or 90; no free-form input — generates a 6-character uppercase alphanumeric invite code via `SecureRandom.alphanumeric(6).upcase`, initializes 6 `GameStock` records at $1.00, sets status to "waiting" — clock does **not** start yet)
  > **Why**: Creating a game and starting it are separate actions — the host needs time to share the invite code and wait for players to join before the clock begins. Duration presets match the original board game and prevent edge cases from arbitrary durations.

- [x] Define a `StartGame` mutation (host-only) to transition the game from "waiting" to "in_progress", compute `ends_at` from the duration, and schedule the game clock expiry job
  > **Why**: Only the host should control when the game starts. `ends_at` is computed at start time (not creation time) so the full duration is available from the moment play begins. The expiry job is scheduled here so it fires at exactly the right time.

- [x] Define a `JoinGame` mutation to join via invite code (if the player was previously in the game, restore their state; otherwise create a new `Player` record with $5,000 cash and 0 shares)
  > **Why**: The invite code is the join mechanism. Restoring state on rejoin means dropped players don't lose their portfolio when they reconnect. New players always start at $5,000 regardless of when they join — mid-game joins are explicitly supported.

- [x] Define a `LeaveGame` mutation to drop out while preserving state
  > **Why**: Players can leave and rejoin without penalty. Preserving state (rather than deleting the player) means their portfolio survives a disconnect or browser close.

- [x] Add a `games` query to list available and active games
  > **Why**: Powers the lobby screen where players can see open games to join. Filters to games in `waiting` or `in_progress` status.

- [x] Add a `game` query to fetch a single game by ID or invite code (includes `ends_at`, remaining time, and `rollsRemainingThisTurn`)
  > **Why**: The primary query for the game board. The client polls or subscribes to this to keep its state in sync. `rollsRemainingThisTurn` is included to prevent client/server desync on the roll count.

- [x] Implement game clock expiry — schedule a background job (Active Job) that fires at `ends_at` to freeze all trading, compute final net worth for all players, and set game status to "completed"
  > **Why**: The game must end automatically when the timer runs out — it can't rely on a player action. A background job scheduled at `ends_at` handles this reliably even if all players close their browsers.

- [ ] **Tie-breaking**: when two or more players share the same net worth at expiry, rank them by `turn_position` ascending (earlier joiner wins); surface tied ranks in the results
  > **Why**: Provides a deterministic, fair tie-breaking rule. Earlier joiners took more risk by playing longer, so they win ties. The rule is communicated upfront so players understand it.

- [ ] Broadcast a `GameEnded` event when the timer expires with final rankings
  > **Why**: All connected clients need to know the game is over so they can transition to the results screen simultaneously. The subscription pushes final rankings so clients don't need to re-query.

- [ ] Support **solo games** — only 1 player; host creates and starts the game alone
  > **Why**: Solo play lets someone learn the game mechanics or play for fun without needing other players. It also enables pause/resume which only makes sense for a single player.

- [ ] Multiplayer games have **no player limit**
  > **Why**: Matches the original board game's open-ended design. Adding artificial limits would require enforcement logic and reduce flexibility.

- [ ] Turn order is determined by **join order**; mid-game joins are appended to the end of the turn order
  > **Why**: Simple, predictable, and fair. The first player to join goes first. Mid-game joins don't disrupt the existing order — they're appended so current players' turns aren't shifted.

- [ ] Mid-game joins always start with **$5,000 cash and 0 shares** regardless of when they join; they must wait for their turn to trade
  > **Why**: Consistent starting conditions regardless of join time. This prevents a strategy of joining late when prices are known. Players must wait for their turn to prevent them from jumping in mid-round.

- [ ] Allow solo players to **pause and resume** a game later via a `PauseGame` mutation (stores `remaining_time` and stops the clock) and a dedicated `ResumeGame` mutation (recomputes `ends_at = Time.current + remaining_time` and reschedules the expiry job)
  > **Why**: Solo games are often played in sessions. Pause/resume lets players save their progress. `remaining_time` is stored so the full remaining duration is preserved across a pause — not just the `ends_at` timestamp.

- [ ] Track player presence (online/offline) within a game using Action Cable connection/disconnect callbacks on `ApplicationCable::Connection`; trigger `PlayerPresenceChanged` on connect and disconnect
  > **Why**: Shows other players who is currently in the game. Also drives auto-roll behaviour — if the active player drops mid-turn, the server detects the disconnect and auto-rolls on their behalf.

- [ ] Write unit tests for game lifecycle mutations, game clock expiry, and queries
  > **Why**: The game lifecycle has many state transitions and edge cases. Tests ensure `CreateGame`, `StartGame`, `JoinGame`, expiry, and tie-breaking all work correctly under various scenarios.

### 6. Implement the dice and turn mechanics

- [ ] Build a dice rolling service that produces 3 results per roll (all dice are **uniformly weighted** — each outcome is equally likely):
  - **Die 1**: Which stock is affected (1/6 each: Grain, Industrial, Bonds, Oil, Silver, Gold)
  - **Die 2**: Direction (1/3 each: Up, Down, or Dividend)
  - **Die 3**: Amount (1/3 each: $0.05, $0.10 or $0.20 movement)
  > **Why**: Encapsulating dice logic in a service keeps the `RollDice` mutation thin and makes the rolling logic independently testable. Uniform weighting matches the original board game's physical dice.

- [ ] Each player rolls **twice per turn** before trading (ROLLS_PER_TURN = 2). The `RollDice` mutation tracks rolls per turn and returns `rollsRemaining`.
  > **Why**: Two rolls per turn is a core rule of the original game. `ROLLS_PER_TURN` is a named constant so the value is defined once and easy to find. Returning `rollsRemaining` from the mutation keeps the client in sync with the server's count.

- [ ] Define a `RollDice` mutation that invokes the dice service and returns the roll result plus `rollsRemaining`
  > **Why**: Rolling dice is a player action that must go through the server to be authoritative. The server applies the price change and returns the result — the client never calculates outcomes itself.

- [ ] Apply price changes to the affected `GameStock` after each roll
  > **Why**: The market moves immediately after each roll, before the next roll. This is the core game mechanic — all players see the updated prices in real time via subscriptions.

- [ ] Share supply is **unlimited** — players may buy as many shares as they can afford
  > **Why**: Matches the original board game. There's no share supply cap to track or enforce, which simplifies the model significantly.

- [ ] **Price floor**: $0.00 is the absolute minimum; any roll that would take a stock below $0 triggers the worthless behavior (wipe shares, reset to $1.00)
  > **Why**: Prevents negative prices which have no meaning in this game. A stock that hits $0 is treated as worthless — all holders lose their shares and the stock resets, matching the original rules.

- [ ] Handle **stock splits** — when a `GameStock` reaches or exceeds $2.00, cap at $2.00, double all holders' shares, and reset the price to $1.00 (no carry-over of excess amount)
  > **Why**: The split is the most exciting event in the game — a big payout for holders. Capping at $2.00 (not allowing carry-over) matches the original rules and prevents runaway prices.

- [ ] Handle **worthless stocks** — when a `GameStock` drops to $0, all holders' shares are immediately removed and the stock resets to $1.00; play continues as normal
  > **Why**: The crash is the most painful event — holders lose everything. Resetting to $1.00 rather than $0 keeps the stock in play so it can recover. Play continues without interruption.

- [ ] Handle **dividends** — the dividend rate matches Die 3 (5%, 10%, or 20% of the stock's current price per share held); dividends only take effect when the `GameStock` price is $1.00 or higher (rolls below $1.00 have no effect)
  > **Why**: Dividends reward holders of high-value stocks. The $1.00 floor prevents dividends from paying out on cheap/recovering stocks, matching the original rules.

- [ ] Enforce the classic turn sequence: roll dice twice -> market moves after each roll -> active player may buy/sell -> end turn
  > **Why**: The server must enforce the sequence — not just document it. Mutations that violate the sequence (e.g., buying before both rolls) must be rejected with an error.

- [ ] Only allow `BuyShares` / `SellShares` mutations from the active player after they have completed both rolls
  > **Why**: Trading before rolling would let players exploit known prices. The server checks both that the caller is the active player and that both rolls are done before allowing any trade.

- [ ] Define an `EndTurn` mutation that advances play to the next player (requires both rolls completed)
  > **Why**: Explicitly ending the turn gives players control over when they're done trading. The server validates both rolls are complete before advancing, preventing players from skipping rolls.

- [ ] If the active player drops mid-turn (between roll 1 and roll 2), auto-roll the remaining roll(s) on their behalf using `DiceRollingService`, then advance to the next player; dropped players are skipped entirely on subsequent turns
  > **Why**: A dropped player shouldn't block the game indefinitely. Auto-rolling completes the market movement so the game continues. Skipping dropped players on subsequent turns keeps pace of play up.

- [ ] Write unit tests for the `RollDice` mutation, turn sequence enforcement, price changes, splits, worthless stocks, and dividends
  > **Why**: The dice mechanics are the core of the game. Tests for each special event (split, crash, dividend) ensure edge cases are handled correctly and regressions are caught.

### 7. Implement buying and selling

- [ ] Define a `BuyShares` mutation to purchase shares at the `GameStock`'s current price (only allowed for the active player after completing both rolls)
  > **Why**: Buying is the primary way players build their portfolio. Server-side validation of player identity, turn state, and cash balance prevents invalid trades.

- [ ] Define a `SellShares` mutation to sell shares at the `GameStock`'s current price (only allowed for the active player after completing both rolls)
  > **Why**: Selling lets players lock in gains or cut losses. Same server-side validation as buying plus a check that the player actually owns the shares they're trying to sell.

- [ ] Validate sufficient cash for purchases (return GraphQL user errors on failure)
  > **Why**: Prevents players from going into debt. Returns a user-facing error (not a server error) so the UI can display it cleanly.

- [ ] Validate sufficient shares for sales (return GraphQL user errors on failure)
  > **Why**: Prevents selling shares that aren't owned (short selling is not part of this game). Returns a user-facing error so the UI can display it cleanly.

- [ ] Shares are bought/sold in lots of 500 shares
  > **Why**: Matches the original board game. Lot-based trading simplifies the UI (fewer buttons, no free-form quantity input) and keeps the numbers meaningful.

- [ ] A player may make multiple buy/sell transactions before ending their turn
  > **Why**: Allows complex trading strategies within a single turn — e.g., selling one stock and buying another. Matches the original board game's trading phase.

- [ ] Update player cash and holdings after each transaction
  > **Why**: Cash and holdings must be updated immediately and atomically so the next transaction sees the correct balances. This prevents double-spending.

- [ ] Log all transactions for game history
  > **Why**: Every trade is recorded in `GameTransaction` for the game log and final results screen. The audit trail also helps debug any balance discrepancies.

- [ ] Add a `transactions` query to fetch game history with pagination
  > **Why**: The full transaction history could be very long in a 90-minute game. Pagination prevents loading thousands of records at once.

- [ ] Write unit tests for buy/sell mutations, validation errors, and edge cases
  > **Why**: Trading is the most financially sensitive part of the app. Tests verify correct cash deduction, holding updates, insufficient funds errors, and edge cases like buying the exact amount of cash remaining.

### 8. Add Redis caching layer

- [ ] Configure Redis as the Rails cache store (in addition to its existing role for Action Cable)
  > **Why**: Redis is already in our stack for Action Cable. Using it for caching too means we get fast in-memory reads for frequently accessed data without adding another service.

- [ ] Cache active game state (stock prices, player holdings, turn info) in Redis
  > **Why**: Game state is read on every subscription update and page load. Caching it in Redis avoids repeated database queries for hot data, keeping response times low during active play.

- [ ] Implement write-through caching so game state is persisted to the database on each mutation
  > **Why**: Redis is not durable — a restart loses all data. Write-through caching ensures every mutation persists to PostgreSQL while Redis serves reads. The database is always the source of truth.

- [ ] Invalidate cache on critical events (game over, player join/leave)
  > **Why**: Stale cache is worse than no cache. Game over, joins, and leaves change the shape of the cached data significantly enough that a full invalidation is safer than partial updates.

- [ ] Use caching for the leaderboard and game listings
  > **Why**: The leaderboard and game list are read by all connected clients frequently. Caching these reduces database load as the number of concurrent games grows.

- [ ] Write tests to verify cache read/write and persistence
  > **Why**: Cache bugs are subtle — data appears correct until the cache is cold or invalidated. Tests that explicitly test cache hits, misses, and invalidation prevent silent data staleness.

### 9. Set up the client-side design system

#### 9a. Tooling

- [ ] Use vanilla JS with `fetch` for GraphQL queries/mutations and importmap for module loading. IMPORTANT: importmap requires bare specifiers in imports (`import GameClient from "game_client"`), NOT relative paths (`"./game_client"`). Pin each module in `config/importmap.rb`.
  > **Why**: No JavaScript framework needed for this app — the UI is relatively simple and the real-time complexity is handled by GraphQL subscriptions. Vanilla JS with importmap avoids a build step (no webpack/esbuild) which keeps the dev environment simple and the Docker image lean.

- [ ] Set up the Action Cable JavaScript client for receiving GraphQL subscriptions
  > **Why**: GraphQL subscriptions are delivered over WebSockets via Action Cable. The JS client must establish and maintain the WebSocket connection and route incoming subscription data to the correct handlers.

- [ ] Write a proof-of-concept that fetches data from the `/graphql` endpoint and receives a subscription update in the browser
  > **Why**: Validates the full stack — Rails, GraphQL, Action Cable, Redis, and the JS client — are all wired together correctly before building real features on top.

#### 9b. Theme and design language

Dark theme with a financial terminal aesthetic. Dark gray background (`#0F172A`), bright accent colors, high-contrast text (`#E2E8F0`).

- [ ] Load fonts from Google Fonts in the layout `<head>`:
  - **Primary**: Inter (weights: 400, 500, 600, 700, 800, 900) — all UI text
  - **Monospace**: JetBrains Mono (weights: 400, 500, 600, 700) — prices, numbers, dice values

```html
<link
  href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600;700&display=swap"
  rel="stylesheet"
/>
```
  > **Why**: Inter is a clean, highly-readable UI font. JetBrains Mono is a developer-focused monospace font that makes numbers and prices easier to scan at a glance — critical for a financial game.

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
  > **Why**: Fixed colors per stock mean players build a visual association between color and commodity quickly. Semantic colors (green = good, red = bad) leverage universal financial UI conventions so the meaning is immediately obvious.

#### 9d. Button styles

- [ ] Create button CSS classes:
  - `btn-primary`: Main CTA (Roll Dice, Start Game, Done Trading). Bold, filled background.
  - `btn-danger`: Destructive action (End Game). Red accent.
  - `btn-ghost`: Secondary action (Add Player, Leave Game). Transparent with border.
  - `btn-small`: Compact variant for header actions.
  - `btn-large`: Full-width variant for primary screen actions.
  - `quick-btn`: Small inline pill-shaped buttons for trading. Subtypes: `quick-buy` (green tint), `quick-sell` (red tint), `quick-max` (italic).
  > **Why**: A consistent button system means every action in the UI has a predictable visual weight. Primary actions are visually prominent; destructive actions are red; ghost buttons are low-emphasis. This reduces cognitive load for players.

#### 9e. Number formatting

- [ ] Implement consistent formatting helpers:
  - **Prices** (stock prices, amounts): `$X.XX`, always 2 decimal places. Stored as integer cents. Display via `(cents / 100).toFixed(2)`.
  - **Money** (cash, net worth, costs): `$X,XXX` with thousand separators, no decimals. Use `toLocaleString('en-US')`.
  - **Shares**: Thousand separators (e.g., "1,500 shares").
  > **Why**: Consistent number formatting prevents confusion. Stock prices always show cents (e.g., $1.05) while cash omits them (e.g., $5,000) because cash amounts are always whole dollars. Thousand separators make large numbers scannable at a glance.

### 10. Build the game UI

The app uses a screen-switching pattern. Only one `.screen` is visible at a time (toggled via the `.active` class). There are 5 screens.

#### 10a. Screen: Username Entry

No authentication — users pick a name and play immediately. (This is the app's actual entry point; replaces the old local pass-and-play setup screen from the original prototype.)

- [ ] Centered card layout with the app logo (SVG bar chart: 4 colored bars — green, blue, amber, red)
- [ ] Title "Stock Ticker" with gradient text (`linear-gradient(135deg, #F59E0B, #EF4444)`)
- [ ] Single text input for display name (placeholder: "Your name", maxlength: 20, autofocus)
- [ ] "Play" button submits a POST to `/join` which creates/finds a `User` and stores `user_id` in the Rails session
- [ ] On success, redirects to the lobby (home screen)
- [ ] CSS class: `username-form`
  > **Why**: The entry point must be as frictionless as possible — no signup, no password. A single name input and one button gets players into the game in seconds. The session cookie ties their name to their browser for the rest of the session.

#### 10b. Screen: Home / Game Lobby

Shown after entering a username. Centered card layout.

- [ ] App logo and title (reuse from username screen)
- [ ] Subtitle: "Playing as **[display_name]**"
- [ ] **Create Game form**: game name input (maxlength: 30), duration select (15/30/60/90 min), "Create Game" button. Calls `CreateGame` mutation.
- [ ] **Join by Code form**: text input (maxlength: 6, uppercase monospace, letter-spacing), "Join" button. Calls `JoinGame` mutation.
- [ ] **Open Games list**: rows showing game name, player count, duration, host name, and a "Join" button. Populated via `games` GraphQL query.
- [ ] If no open games: "No open games yet. Create one!" message.
- [ ] CSS classes: `setup-container`, `lobby-actions`, `create-game-form`, `join-game-form`, `game-list-section`, `game-list`, `game-list-item`, `game-list-empty`
  > **Why**: The lobby gives players two ways to join — by browsing open games or entering a code shared by a friend. Both paths lead to the same `JoinGame` mutation. The open games list enables discovery for players who don't have a code.

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
  > **Why**: The waiting room is where players gather before the game starts. The prominent invite code with a copy button makes it easy to share. Real-time player list updates via subscription mean everyone sees who has joined without refreshing.

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
  > **Why**: The countdown timer is one of the most important UI elements — it drives urgency and informs trading decisions. Visual urgency cues (red, pulse) at 5 min and 1 min give players clear warnings before the game ends.

##### Event Ticker

- [ ] Horizontally scrolling marquee strip below the header
- [ ] Event items colored by type: `.up` (green), `.down` (red), `.dividend` (amber), `.split` (blue), `.crash` (red bold), `.trade` (neutral)
- [ ] Content duplicated (`items + items`) for seamless CSS animation loop (`ticker-scroll 30s linear infinite`)
- [ ] Maximum 50 events stored, most recent 20 displayed
  > **Why**: The ticker gives the game a live financial market feel. Players who aren't currently rolling can follow the action. The CSS-only animation is performant and doesn't require JS timers.

##### Phase Banner

- [ ] Full-width colored bar below the event ticker
- [ ] Rolling phase: blue tint (`phase-rolling`), shows "Roll 1 of 2" or "Roll 2 of 2" + active player name in their color
- [ ] Trading phase: green tint (`phase-trading`), shows "Buy & Sell" + active player name
- [ ] When not your turn: shows whose turn it is
  > **Why**: In multiplayer, players need to know at a glance whose turn it is and what phase the game is in. The phase banner is always visible and uses colour to communicate state without requiring players to read carefully.

##### Game Log (left sidebar)

- [ ] **Last roll section**: Three dice values as small colored badges — stock symbol in its commodity color, direction colored green/red/amber (`die-up`, `die-down`, `die-dividend`), amount in neutral. Below: outcome message colored by event type.
- [ ] **Net worth tracker**: All players ranked by net worth descending. Each entry shows:
  - Player name (in their player color if it's you)
  - Current net worth in monospace (`nw-current`)
  - Change since last roll: green `+$X` (`nw-change positive`), red `-$X` (`nw-change negative`), gray dash (`nw-change neutral`)
  - Colored bar below proportional to max net worth (`nw-bar`)
- [ ] Client MUST snapshot all players' net worth before each roll, then show the diff after
- [ ] CSS classes: `game-log`, `log-panel`, `last-roll`, `last-roll-result`, `last-roll-dice`, `last-roll-die`, `last-roll-message`, `net-worth-tracker`, `nw-entry`, `nw-name`, `nw-values`, `nw-current`, `nw-change`, `nw-bar`
  > **Why**: The game log serves two purposes: it shows what just happened (last roll) and how everyone is doing (net worth tracker). The per-roll net worth delta is important — players need to see the immediate impact of each roll, not just the cumulative total.

##### Stock Board (center)

- [ ] 1x6 horizontal grid of **static** stock cards in fixed order: Grain, Industrial, Bonds, Oil, Silver, Gold

```css
.stock-board {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 0.75rem;
}
```

- [ ] Cards are created ONCE via `initStockBoard()` when entering the game. DOM positions NEVER change. Only text content (price, change) is updated in place via `renderStockBoard()`. This prevents cards from jumping or reordering.
- [ ] Each card contains: `.stock-name` (in stock color), `.stock-price` (monospace), `.stock-change`, `.stock-card-trade-slot` (empty container for trade controls)
- [ ] `stock-change` shows the change from the **last time this stock's price changed** (previous roll that affected it), NOT overall from $1.00. Client tracks each stock's previous price.
- [ ] **Flash animations**: When a stock is affected by a roll, the card flashes for 600ms:
  - `flash-up`: green glow | `flash-down`: red glow | `flash-dividend`: amber glow
  - Triggered by adding class, forcing reflow (`void card.offsetWidth`), then removing after timeout
  > **Why**: Fixed card positions mean players build spatial memory of where each stock is. Cards created once and updated in-place (never recreated) prevents visual jumping. Flash animations draw the eye to the affected stock without requiring players to scan all 6 cards.

##### Trading Phase (inline on stock cards)

- [ ] When `rollsRemaining` reaches 0, each card gains `.trading` class and the `.stock-card-trade-slot` is populated with buy/sell controls. Cards animate taller (CSS transition on `max-height`).
- [ ] Trade controls per card: holdings info (`trade-holdings`), buy row, sell row
- [ ] Quick lot buttons: presets `[1, 5, 10, 25]`. Show only presets the player can afford (buy) or owns (sell). Add "Max(N)" / "All(N)" if the max isn't a preset. Show em-dash if none available.
- [ ] Buttons use event delegation on `#stock-board` for click handling
- [ ] "Done Trading" button in a separate `trade-actions` container below the board. Calls `EndTurn` mutation.
- [ ] When not your turn or during rolling: cards show market data only, no trade controls.
  > **Why**: Inline trade controls on the stock cards keep the interaction close to the data — players can see the price and buy/sell in the same place. Preset lot buttons (rather than a text input) are faster to tap and match the lot-based trading model. Showing only affordable/owned presets prevents invalid trades before they happen.

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
  > **Why**: The dice animation creates anticipation — it's the most exciting moment of each turn. 15 ticks at 80ms is fast enough to feel like rolling without being annoying. Syncing `rollsRemaining` from the server prevents the client from getting out of step if a message is missed.

##### Right Sidebar: Your Portfolio

- [ ] Panel with border color = your player color
- [ ] Header: your name + phase label ("Rolling (1/2)", "Trading", "Watching")
- [ ] Stats: Cash (green), Net Worth — in `stat-box` containers
- [ ] Holdings list: stock symbol (in color), share count, current value. "No stocks held" if empty.
  > **Why**: Players need to see their own financial state at all times — cash balance determines what they can buy, and current holdings determine what they can sell. The phase label reminds them what they should be doing right now.

##### Right Sidebar: Scoreboard

- [ ] All players ranked by net worth descending
- [ ] Each entry: rank number, player name (active player highlighted with `.active` class in their color), net worth in monospace
- [ ] Bar chart: width proportional to max net worth, colored by player color
- [ ] In multiplayer: online/offline dot next to each name
  > **Why**: The scoreboard creates competitive tension — players can see exactly how far ahead or behind they are. The bar chart makes relative standings visually obvious at a glance. The online/offline indicator shows who is still active in the game.

##### Right Sidebar: Chat

- [ ] Message list (scroll, newest at bottom, auto-scroll on new)
- [ ] Author name in player color + message text
- [ ] Input field (maxlength: 200) + "Send" button. Enter key also sends.
- [ ] Sends via `SendMessage` mutation. Receives via `MessageReceived` subscription.
  > **Why**: Chat adds a social layer to the game. Player names in their color make it easy to identify who said what at a glance. Auto-scroll keeps the latest messages visible without user interaction.

##### Toast Notifications

- [ ] Floating notification for splits, crashes, dividends
- [ ] Created dynamically, appended to `<body>`. Types: `split-toast`, `crash-toast`, `dividend-toast`.
- [ ] Slide-in animation (`.show` class), auto-dismiss after 2500ms (300ms fade-out).
- [ ] Only one toast at a time.
  > **Why**: Splits, crashes, and large dividends are significant events that deserve prominent callouts — not just a line in the ticker. Toasts appear on top of the UI and auto-dismiss so they don't require player interaction but still grab attention.

#### 10e. Screen: Game Over / Results

- [ ] Trophy emoji, "Game Over" heading
- [ ] Players sorted by final net worth descending; ties broken by `turn_position` ascending (earlier joiner ranks higher). Rank 1/2/3 use medal emojis, rank 4+ numeric.
- [ ] Each entry: player name (in their color), profit/loss amount and percentage vs. starting $5,000, final net worth.
- [ ] "Play Again" button (returns to lobby). In multiplayer, also "Back to Lobby".
- [ ] Triggered by `GameEnded` subscription.
  > **Why**: The results screen gives players closure and a clear winner. Profit/loss vs. starting $5,000 shows each player how well they did in absolute terms, not just relative to others. Medal emojis for top 3 add personality. "Play Again" reduces friction for a second game.

#### 10f. Responsive layout

- [ ] **Desktop (1200px+)**: Three-column layout. 1x6 stock card row.
- [ ] **Tablet (768-1199px)**: Single column. Game log above board. Sidebar below. Stock board 3x2 grid.
- [ ] **Mobile (<768px)**: Single column. Stock board 2x3 grid. Chat in slide-out drawer. Game log above board.
  > **Why**: The game is primarily a desktop experience but should be playable on tablets. Mobile is a stretch goal — the three-column layout doesn't fit on small screens so the layout reflows. Chat moves to a drawer on mobile to save vertical space.

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
  > **Why**: A single `render()` function called on every state change keeps the UI predictable — there's no risk of forgetting to update a panel when state changes. Each sub-renderer is responsible for one area of the UI, making them independently testable and easy to find.

### 11. Add real-time updates with GraphQL subscriptions

- [ ] Define a `GameStarted` subscription to notify players in the lobby that the host has started the game
  > **Why**: Players in the waiting room need to transition to the game board the moment the host starts the game — they can't be expected to manually refresh.

- [ ] Define a `GameStockPriceUpdated` subscription to push per-game price changes to all players in that game
  > **Why**: All players must see price changes immediately after each roll, not just the active player. This is the primary subscription driving the live market board.

- [ ] Define a `DiceRolled` subscription to broadcast roll results in real time
  > **Why**: Non-active players need to see the dice roll result and animation play out on their screen, not just the price change. This keeps all players engaged even when it's not their turn.

- [ ] Define a `LeaderboardUpdated` subscription to push net worth changes
  > **Why**: After every price change and trade, all players' net worths change. Pushing updates to all clients keeps the scoreboard and net worth tracker live.

- [ ] Define a `TurnChanged` subscription to notify players when it's their turn
  > **Why**: Players need a clear signal when it becomes their turn so they know to take action. This also updates the phase banner and active player indicator for all clients.

- [ ] Define a `PlayerPresenceChanged` subscription for join/leave/rejoin events
  > **Why**: All players in a game should see when someone joins, leaves, or reconnects. Drives the player list in the waiting room and the online/offline dot in the scoreboard.

- [ ] Define a `GameEnded` subscription to notify all players when the game clock expires (includes final rankings)
  > **Why**: When the timer hits zero, all clients need to simultaneously transition to the results screen. The subscription includes final rankings so clients don't need to make a separate query.

- [ ] Configure Action Cable as the transport layer for GraphQL subscriptions
  > **Why**: Action Cable is Rails' built-in WebSocket framework. Using it as the transport for GraphQL subscriptions means we don't need a separate WebSocket server — the same Puma process handles both HTTP and WebSocket connections.

- [ ] Write integration tests for subscription delivery
  > **Why**: Subscriptions are harder to test than queries/mutations because they're asynchronous. Integration tests verify that the right events are delivered to the right subscribers in the right order.

### 12. Add a real-time chat room

- [ ] Define a `SendMessage` GraphQL mutation to post chat messages
  > **Why**: Going through GraphQL (rather than a separate Action Cable channel) keeps all real-time communication in one place and benefits from GraphQL's validation and error handling.

- [ ] Define a `MessageReceived` GraphQL subscription for real-time message delivery
  > **Why**: Pushes new messages to all players in the game instantly. Scoped to the game so players only receive messages from their current game.

- [ ] Build a chat room UI in the right sidebar within the game view
  > **Why**: Chat is a secondary feature — it lives in the sidebar rather than taking up prime space on the game board. Keeping it always visible (on desktop) means players can glance at it without switching screens.

- [ ] Emoji support via native browser emoji only — no custom picker; ensure the chat input and message rendering handle Unicode emoji correctly (UTF-8 column, no stripping)
  > **Why**: Native emoji (from the OS keyboard) covers the use case without adding a third-party emoji picker library. The database column must be UTF-8 (not latin1) to store emoji without corruption.

- [ ] Display active players in the chat
  > **Why**: Knowing who is currently in the game helps players direct messages appropriately and know if anyone is watching.

- [ ] Write tests for the mutation, subscription, and message delivery
  > **Why**: Chat is simple but the subscription delivery path (mutation → broadcast → subscriber) has several moving parts that can silently fail without tests.

### 13. Write the game rules document

- [ ] Create a `RULES.md` file with full game rules and how to play
  > **Why**: New players need a reference document to understand the game before playing. In-game tooltips alone aren't enough for first-time players.

- [ ] Include commodity descriptions and starting prices
  > **Why**: Players may not know what each commodity represents or why they start at $1.00. Brief descriptions add context and personality.

- [ ] Document dice mechanics (3-die system, outcomes, 2 rolls per turn)
  > **Why**: The dice system is the core mechanic and needs clear documentation — especially the fact that each die is independent and uniformly weighted.

- [ ] Explain stock splits, worthless stocks, and dividends
  > **Why**: These are the three special events that dramatically change the game state. Players need to understand them before they happen to make informed trading decisions.

- [ ] Cover buying/selling rules and lot sizes
  > **Why**: The lot-based trading model (multiples of 500) is different from what players might expect. Clear documentation prevents confusion during the trading phase.

- [ ] Describe game types (solo vs. multiplayer)
  > **Why**: Solo and multiplayer have different features (pause/resume, player limit, turn dynamics). Players choosing a game mode should know what to expect.

- [ ] Add win conditions and scoring
  > **Why**: Players need to know how to win — highest net worth at timer expiry, with tie-breaking by join order. This should be stated clearly so there are no disputes at the end.
