<!-- Copilot instructions for AI coding agents working on Stock Ticker -->
# Stock Ticker — Copilot guidance

Short, actionable guidance so an AI agent is productive immediately.

- **Big picture**: This is a Ruby on Rails web app exposing a single GraphQL endpoint (`/graphql`) with mutations, queries, and GraphQL subscriptions for real-time gameplay. Real-time transport uses Action Cable + Redis. Primary development flow is Docker Compose (Colima) — see `README.md` for commands.

- **Primary surfaces**:
  - Server: Rails app (models in `app/models`, services in `app/services`, jobs in `app/jobs`).
  - API: `app/graphql` (types, mutations, subscriptions). Use existing naming: `GameType`, `GameStockType`, `PlayerType`.
  - Real-time: Action Cable channels under `app/channels` and GraphQL subscriptions in `app/graphql/subscriptions`.
  - Client: vanilla JS with importmap; follow `stock-ticker-task-list.md` UI render cycle (create DOM once, update in place).

- **Developer workflows (exact commands)**:
  - Start Colima: `colima start --cpu 4 --memory 6 --vm-type vz --vz-rosetta`
  - Run app: `docker-compose up --build`
  - First-time DB setup (in second terminal): `docker-compose exec app bin/docker-setup`
  - Tests (inside container): `docker-compose exec app bin/rails test` or locally `bundle exec rails test`.

- **Important project conventions** (do not change without confirmation):
  - Stock ordering is fixed: Grain, Industrial, Bonds, Oil, Silver, Gold. Many client layouts assume this order.
  - Prices are stored in integer cents (e.g., 100 = $1.00). Display helpers convert cents → `$X.XX` (see UI number-formatting notes in `stock-ticker-task-list.md`).
  - Shares are transacted in lots of 500. Holdings quantities are integers in multiples of 500.
  - Client DOM rule: `initStockBoard()` creates six stock cards once; `renderStockBoard()` updates text only — never reorder or recreate cards.
  - Invite codes: 6-character uppercase alphanumeric via `SecureRandom.alphanumeric(6).upcase`.

- **Data & behavior notes to reference**:
  - Splits: when a `GameStock` reaches $2.00 cap, double holders' shares and reset to $1.00 (no carry-over). See Task 6/7 in `stock-ticker-task-list.md`.
  - Worthless reset: when price hits $0, remove holders and reset to $1.00.
  - Dividends: pay based on Die 3 percent (5/10/20%) and only if price >= $1.00.
  - Turn order: join order determines `turn_position`; active player computed by offsetting `current_turn` modulo active players (see `OPEN-ISSUES.md` notes for precise formula).

- **Files you should read first**:
  - `README.md` — setup, Docker-first workflow, tech stack
  - `stock-ticker-task-list.md` — canonical source of domain rules, GraphQL shape, client expectations
  - `OPEN-ISSUES.md` — known documentation gaps and required clarifications (follow these when implementing)

- **When making changes or adding features**:
  - Preserve the Docker-first constraint: any infra changes must update `docker-compose.yml` and verify `docker-compose up` still works.
  - Update or add GraphQL schema types under `app/graphql` and keep naming consistent (`GameStockType`, `GameType`, `PlayerType`).
  - Add Sorbet signatures when modifying models/services (project intends to use Sorbet), but do not break CI if Sorbet isn't fully configured.

- **Testing & background jobs**:
  - Background jobs (game clock expiry) must be scheduled via Active Job; in development the desired adapter is `:async` (see `OPEN-ISSUES.md`).
  - Use `docker-compose exec app bin/rails test` to run tests in the canonical environment.

- **Client-specific patterns** (examples)
  - Importmap usage: client modules use bare specifiers (e.g., `import GameClient from "game_client"`) and are pinned in `config/importmap.rb`.
  - Dice/roll UI: `RollDice` mutation updates `rollsRemainingThisTurn` — client should always sync `rollsRemaining` from server to avoid desync.

- If anything here looks incomplete or you want a different level of detail (e.g., snippets for common GraphQL mutations or example curl requests), tell me which sections to expand.
