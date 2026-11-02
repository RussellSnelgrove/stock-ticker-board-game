# Open Issues

Design questions and how the code answers them. Entries marked **Provisional** were decided during the build-out without the owner's input; change them if you disagree.

---

## Data Model Field Types (Task 4)

**Q1: Should `GameTransaction.price_at_time` and `total_amount` be stored as integer cents, consistent with `GameStock.current_price` and `Player.cash`?**

Answer: Yes. Every money column is integer cents.

---

**Q2: What type should `Game.duration` and `Game.remaining_time` use?**

Answer: `duration` is integer minutes (the presets 15, 30, 60, 90). `remaining_time` is integer seconds, set only while a game is paused.

---

**Q3: Should `Game.status` and `Player.status` be stored as Rails enums (integer-backed) or string columns?**

Answer: String columns behind Rails enums (`enum :status, { waiting: "waiting", ... }`). The database stays readable and the enum helpers still exist.

---

## Game Lifecycle

**Q4: What should happen if a solo player calls `JoinGame` on their own paused game?**

Answer (**Provisional**): Option B. `JoinGame` restores the player and leaves the clock stopped; the player resumes with `ResumeGame`. Other users cannot join a paused game.

---

**Q4a: What makes a game "solo"?**

Answer (**Provisional**): A game with exactly one player record. Only solo games can be paused. Anyone with the invite code can still join an unpaused solo game, which then becomes multiplayer and can no longer be paused.

---

## Dice and Turn Mechanics

**Q5: What triggers the auto-roll when the active player drops mid-turn?**

Answer (**Provisional**): Option A. `LeaveGame` makes the remaining rolls inline, marks the player dropped, and passes the turn. A WebSocket disconnect only marks the player offline; it does not count as leaving, so a page reload never forfeits a turn.

---

**Q5a: How is the active player tracked?**

Answer (**Provisional**): `Game.active_player_id` stores it. The original formula, `players.active.order(:turn_position).offset(current_turn % active_player_count)`, changed whose turn it was whenever a player joined, left, or rejoined mid-turn. `EndTurn` now passes play to the next active player by `turn_position`, wrapping around and skipping dropped players. `current_turn` counts completed turns.

---

**Q5b: Are quick-trade presets `[1, 5, 10, 25]` shares or lots?**

Answer (**Provisional**): Lots of 500 shares. The `BuyShares` and `SellShares` mutations take a share `quantity` that must be a positive multiple of 500.

---

## Real-time Subscriptions

**Q6: How should `PlayerPresenceChanged` know which game to broadcast to on disconnect?**

Answer (**Provisional**): Option B. On connect and disconnect, `Presence.update` finds the user's players in every game that is not completed, flips `players.online`, and triggers `PlayerPresenceChanged` for each game. A user with two tabs open goes offline when either tab closes.

---

## Chat

**Q7: What does "display active players in the chat" mean?**

Answer (**Provisional**): Option A. The chat panel lists the players who are online.

---

## Still open

**Redis caching of full game state (Task 8).** The leaderboard and lobby listing are cached. Caching the whole game state was not built: GraphQL resolves fields from Active Record objects, so a cached hash would bypass the types, and PostgreSQL serves a single game's reads quickly. Build it only if profiling shows game reads are slow.

**Cash display.** Task 9e formats cash as whole dollars, but dividends can pay cents (500 shares at $1.05 with a 10% dividend pays $52.50). The server keeps exact cents; the client rounds for display.
