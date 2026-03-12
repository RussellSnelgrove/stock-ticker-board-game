# Open Issues

Questions to resolve before or during development

---

## Data Model Field Types (Task 4)

**Q1: Should `GameTransaction.price_at_time` and `total_amount` be stored as integer cents, consistent with `GameStock.current_price` and `Player.cash`?**

Answer:

---

**Q2: What type should `Game.duration` and `Game.remaining_time` use?**
- Option A: Integer seconds (e.g., 3600 = 60 min). Consistent with Ruby's `Time` arithmetic.
- Option B: Integer minutes (e.g., 60 = 60 min). Simpler for duration presets; `remaining_time` would also be minutes.

Answer:

---

**Q3: Should `Game.status` and `Player.status` be stored as Rails enums (integer-backed) or string columns?**
- Option A: Rails enum (integer-backed) — more efficient, enum helpers generated automatically.
- Option B: String column — more readable in the database, easier to debug.

Answer:

---

## Game Lifecycle

**Q4: What should happen if a solo player calls `JoinGame` on their own paused game?**
`JoinGame` currently "restores state" for previously-joined players. If the game is paused, should `JoinGame`:
- Option A: Return an error telling the player to use `ResumeGame` instead.
- Option B: Silently succeed (restore state, do NOT resume the clock — player must then call `ResumeGame`).

Answer:

---

## Dice and Turn Mechanics

**Q5: What triggers the auto-roll when the active player drops mid-turn?**
The task says to auto-roll remaining rolls on behalf of a dropped active player. Should this be triggered:
- Option A: Inline inside the `LeaveGame` mutation — if the leaving player is the active player and `rolls_remaining_this_turn > 0`, auto-roll immediately.
- Option B: As a separate background job that detects the condition and fires.

Answer:

---

## Real-time Subscriptions

**Q6: How should `PlayerPresenceChanged` know which game to broadcast to on disconnect?**
Action Cable disconnect fires on the connection object, not a channel. The connection needs to know which game the player was in. Should this be:
- Option A: Store `game_id` on the connection object when the player subscribes to the game channel; use it on disconnect.
- Option B: Look up the player's active game from the database on disconnect.

Answer:

---

## Chat

**Q7: What does "display active players in the chat" mean?**
- Option A: A persistent list of currently-online players shown in the chat sidebar.
- Option B: System messages in the message feed (e.g., "Russell joined the game").
- Option C: Both.

Answer:
