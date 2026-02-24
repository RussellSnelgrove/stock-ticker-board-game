# Stock Ticker UI Specification

Reference document for recreating the Stock Ticker game UI. Based on the existing prototype and extended for the multiplayer Rails + GraphQL version.

## Design Language

### Theme

Dark theme with a financial terminal aesthetic. Dark gray background, bright accent colors for stocks and player identities, high-contrast text.

### Typography

- **Primary font**: Inter (weights: 400, 500, 600, 700, 800, 900)
- **Monospace font**: JetBrains Mono (weights: 400, 500, 600, 700) -- used for prices, numbers, dice values
- Load from Google Fonts:

```html
<link
  href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600;700&display=swap"
  rel="stylesheet"
/>
```

### Color Palette

**Stock colors** (each commodity has a fixed color throughout the app):

| Stock      | Symbol | Color   |
| ---------- | ------ | ------- |
| Gold       | GOLD   | #F59E0B |
| Silver     | SLVR   | #94A3B8 |
| Bonds      | BNDS   | #3B82F6 |
| Oil        | OIL    | #10B981 |
| Industrial | IND    | #EF4444 |
| Grain      | GRN    | #D97706 |

**Player colors** (assigned by join order, cycle if more than 4 players):

| Position | Color   |
| -------- | ------- |
| 1        | #3B82F6 |
| 2        | #EF4444 |
| 3        | #22C55E |
| 4        | #F59E0B |

**Semantic colors**:

| Purpose     | Color   | Usage                                   |
| ----------- | ------- | --------------------------------------- |
| Up/gain     | #22C55E | Stock price increase, positive P&L      |
| Down/loss   | #EF4444 | Stock price decrease, negative P&L      |
| Dividend    | #F59E0B | Dividend payouts                        |
| Split       | #3B82F6 | Stock split events                      |
| Crash       | #EF4444 | Worthless stock events (brighter flash) |
| Buy action  | #22C55E | Buy buttons                             |
| Sell action | #EF4444 | Sell buttons                            |

### Button Styles

Three button tiers used throughout:

- `btn-primary`: Main CTA (Roll Dice, Start Game, Done Trading). Bold, filled background.
- `btn-danger`: Destructive action (End Game). Red accent.
- `btn-ghost`: Secondary action (Add Player). Transparent with border.
- `btn-small`: Compact variant for header actions.
- `btn-large`: Full-width variant for primary screen actions.

Quick trade buttons (`quick-btn`) are small, inline pill-shaped buttons:

- `quick-buy`: Green tint for buy actions.
- `quick-sell`: Red tint for sell actions.
- `quick-max`: Slightly different style to indicate "all remaining".

---

## Screens

The app uses a screen-switching pattern. Only one `.screen` is visible at a time (toggled via the `.active` class). The multiplayer version adds two new screens (Home/Lobby, Waiting Room) to the three from the prototype.

### Screen 1: Home / Game Browser (new for multiplayer)

Not in the prototype. This is the landing page after login.

**Layout**: Centered card layout, similar to the setup screen.

**Components**:

- App logo and title (reuse the SVG bar-chart logo from the setup screen)
- Two primary actions: "Create Game" button and "Join by Code" input with submit button
- "Your Active Games" list: rows showing game name, player count, remaining time, with a "Resume" link
- "Open Games" list: rows showing game name, player count, host name, with a "Join" button

### Screen 2: Waiting Room (new for multiplayer)

Not in the prototype. Shown after creating or joining a game that is in "waiting" status.

**Layout**: Centered card, similar to setup screen.

**Components**:

- Game name as heading
- Invite code displayed prominently (large monospace text, with a copy-to-clipboard button)
- Duration badge showing selected play time (e.g., "60 min")
- Player list showing join order: numbered 1, 2, 3... with player name and a colored dot using their player color. Host is labeled "(host)".
- "Start Game" button: only visible to the host, large primary button at the bottom
- "Leave Game" link/button for non-host players

The waiting room should subscribe to player join/leave events and update the player list in real time. When the host starts the game, all clients receive the `GameStarted` subscription and transition to the game screen.

### Screen 3: Setup Screen (prototype: local pass-and-play only)

From the prototype. Used for local games. In the multiplayer version this screen is replaced by the Home + Waiting Room flow, but it can be kept for offline/local play.

**Structure**:

```html
<div id="setup-screen" class="screen active">
  <div class="setup-container">
    <div class="setup-logo">
      <!-- SVG bar chart icon (4 colored bars: green, blue, amber, red) -->
      <h1>Stock Ticker</h1>
      <p class="setup-subtitle">The Classic Board Game</p>
    </div>
    <div class="setup-players">
      <h2>Players</h2>
      <div id="player-inputs">
        <!-- Dynamically rendered player input rows -->
      </div>
      <button id="add-player-btn" class="btn btn-ghost">+ Add Player</button>
    </div>
    <button id="start-game-btn" class="btn btn-primary btn-large">
      Start Game
    </button>
  </div>
</div>
```

**Player input row** (`player-input-row`):

- Colored number badge (`.player-number.player-color-N`) using the player color palette
- Text input for player name (placeholder: "Player N", maxlength: 20)
- Remove button (`&times;`) shown only when there are 2+ players
- "Add Player" button hidden when at max players

### Screen 4: Game Screen (the main gameplay screen)

The core of the UI. Uses a two-column layout: main content area (left/center) and sidebar (right).

**Top-level structure**:

```html
<div id="game-screen" class="screen">
  <header class="game-header">...</header>
  <div id="event-ticker" class="event-ticker">...</div>
  <div id="phase-banner" class="phase-banner">...</div>
  <div class="game-layout">
    <div class="game-main">
      <div id="stock-board" class="stock-board">...</div>
      <div id="dice-area" class="dice-area">...</div>
      <!-- No separate trade section — buy/sell controls appear on stock cards during trading phase -->
      <div id="trade-actions" class="trade-actions hidden">
        <button id="end-turn-btn" class="btn btn-primary btn-large">Done Trading</button>
      </div>
    </div>
    <div class="game-sidebar">
      <div id="current-player-panel" class="panel current-player-panel">
        ...
      </div>
      <div class="panel scoreboard-panel">...</div>
      <!-- NEW: chat panel for multiplayer -->
    </div>
  </div>
</div>
```

#### Game Header

```html
<header class="game-header">
  <div class="header-left">
    <h1 class="game-title">Stock Ticker</h1>
    <span id="round-display" class="round-badge">Round 1</span>
    <!-- NEW: countdown timer for multiplayer -->
    <span id="game-clock" class="clock-badge">47:23</span>
  </div>
  <div class="header-right">
    <!-- NEW: pause button for solo games -->
    <button id="end-game-btn" class="btn btn-danger btn-small">End Game</button>
  </div>
</header>
```

- `round-badge`: Small pill badge showing the current round number.
- `clock-badge` (new): Countdown timer, same style as round badge but more prominent. Turns red when under 5 minutes. Pulses when under 1 minute.

#### Event Ticker

A horizontally scrolling marquee strip below the header. Shows recent game events.

```html
<div id="event-ticker" class="event-ticker">
  <div id="event-ticker-content" class="event-ticker-content">
    <span class="event-item up">Gold ▲ $0.10 → $1.10</span>
    <span class="event-item dividend">Bonds pays $0.05/share dividend</span>
    <span class="event-item crash">CRASH! Oil drops to $0 — shares wiped</span>
    ...
  </div>
</div>
```

- Uses CSS animation for continuous horizontal scroll.
- Event items are colored by type: `up` (green), `down` (red), `dividend` (amber), `split` (blue), `crash` (red, bold), `trade` (neutral).
- Content is duplicated (`items + items`) to create a seamless loop.
- Maximum 50 events stored, most recent 20 displayed.

#### Phase Banner

A full-width colored bar indicating the current game phase and active player.

```html
<div id="phase-banner" class="phase-banner phase-rolling">
  <span class="phase-label">Rolling Phase</span>
  <span class="phase-detail">
    <span class="phase-player" style="color: #3B82F6">Russell</span>
    — Roll 1 of 2
  </span>
</div>
```

- `phase-rolling`: Background tint indicating rolling phase.
- `phase-trading`: Different background tint for trading phase.
- Player name is rendered in their assigned player color.
- In multiplayer, when it's NOT your turn, the banner should indicate whose turn it is and what they're doing.

#### Stock Board

A 1x6 horizontal row of stock cards, one per commodity. The board spans the full width of the main content area, with all 6 cards in a single row.

```css
.stock-board {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 0.75rem;
}
```

**During the rolling phase**, stock cards show market data only:

```html
<div id="stock-board" class="stock-board">
  <div class="stock-card" data-stock="0">
    <div class="stock-name">Gold</div>
    <div class="stock-price">$1.20</div>
    <div class="stock-change up">+$0.20 (+20%)</div>
    <canvas class="stock-sparkline" data-stock="0" width="140" height="32"></canvas>
  </div>
  <!-- ... 5 more cards -->
</div>
```

**During the trading phase**, each card expands vertically to reveal inline buy/sell controls below the sparkline. The card gains the `.trading` class:

```html
<div class="stock-card trading" data-stock="0">
  <div class="stock-name">Gold</div>
  <div class="stock-price">$1.20</div>
  <div class="stock-change up">+$0.20 (+20%)</div>
  <canvas class="stock-sparkline" data-stock="0" width="140" height="32"></canvas>
  <!-- Trade controls — only rendered during trading phase -->
  <div class="stock-card-trade">
    <div class="trade-holdings">3 lots (1,500 shares) <span class="trade-lot-cost">$600/lot</span></div>
    <div class="trade-quick-row">
      <span class="trade-row-label buy-label">Buy</span>
      <div class="quick-btn-group">
        <button class="quick-btn quick-buy" data-stock="0" data-action="buy" data-lots="1">1</button>
        <button class="quick-btn quick-buy" data-stock="0" data-action="buy" data-lots="5">5</button>
        <button class="quick-btn quick-buy quick-max" data-stock="0" data-action="buy" data-lots="8">Max(8)</button>
      </div>
    </div>
    <div class="trade-quick-row">
      <span class="trade-row-label sell-label">Sell</span>
      <div class="quick-btn-group">
        <button class="quick-btn quick-sell" data-stock="0" data-action="sell" data-lots="1">1</button>
        <button class="quick-btn quick-sell" data-stock="0" data-action="sell" data-lots="3">All(3)</button>
      </div>
    </div>
  </div>
</div>
```

The transition from rolling to trading should animate smoothly -- cards grow taller as the `.stock-card-trade` section slides in. Use a CSS transition on `max-height` or an expand animation.

**Stock card details**:

- `stock-name`: Commodity name in the stock's color.
- `stock-price`: Current price in large monospace font (JetBrains Mono).
- `stock-change`: Price change from $1.00 starting price, with percentage. Colored by direction: `.up` (green), `.down` (red), `.flat` (gray). Includes +/- sign.
- `stock-sparkline`: Canvas element drawing a mini line chart of price history (last 30 data points). Uses the stock's color. Includes a gradient fill below the line (20% opacity at top, 5% at bottom).
- `stock-card-trade`: Container for the inline buy/sell controls. Only rendered when the game is in the trading phase. Hidden during rolling.

**Inline trade controls** (inside each stock card):

- `trade-holdings`: Shows current shares held and lot cost. Compact single line.
- `trade-quick-row` with `buy-label` / `sell-label`: Buy and sell rows with quick lot buttons.
- Quick button logic is the same as before (preset lots: 1, 5, 10, 25; "Max(N)" / "All(N)" buttons; em-dash when nothing available).
- Buttons use event delegation on `#stock-board` for click handling.

**"Done Trading" button**: Displayed below the stock board in a separate `trade-actions` container (not inside any card). Visible only during trading phase.

**Flash animations**: When a stock is affected by a dice roll, the card briefly flashes:

- `flash-up`: Green border/glow flash (600ms).
- `flash-down`: Red border/glow flash (600ms).
- `flash-dividend`: Amber border/glow flash (600ms).

Implemented by adding the class, forcing reflow (`void card.offsetWidth`), then removing after 600ms.

**Sparkline rendering** (canvas):

- Accounts for `devicePixelRatio` for crisp rendering on retina displays.
- Line: 1.5px stroke in the stock's color, round line joins.
- Fill: Gradient from `color + '20'` (top) to `color + '05'` (bottom).
- Y-axis auto-scales with 5-cent padding above and below data range.

**Multiplayer behavior**: During the trading phase, only the active player sees interactive buy/sell buttons on the cards. Other players see the cards in their rolling-phase (market data only) state, or a muted version with a "Waiting for [player] to trade..." message below the board.

#### Dice Area

Visible during the rolling phase. Hidden during trading phase.

```html
<div id="dice-area" class="dice-area">
  <div class="dice-container">
    <div class="die" id="die-stock">
      <span class="die-label">Stock</span>
      <span class="die-value">?</span>
    </div>
    <div class="die" id="die-direction">
      <span class="die-label">Action</span>
      <span class="die-value">?</span>
    </div>
    <div class="die" id="die-amount">
      <span class="die-label">Amount</span>
      <span class="die-value">?</span>
    </div>
  </div>
  <div id="dice-message" class="dice-message"></div>
  <button id="roll-btn" class="btn btn-primary btn-large roll-btn">
    Roll Dice
  </button>
</div>
```

**Die element**: A square/rounded-square container with a small label on top and large value in the center. Uses monospace font for values.

**Dice roll animation**:

1. All 3 dice get the `.rolling` class (CSS animation: shake/wobble).
2. Roll button is disabled.
3. 15 ticks at 80ms intervals: random values cycle through each die (stock symbols, UP/DOWN/DIV, cent amounts).
4. After animation completes, final values are set:
   - Stock die: Shows the commodity symbol, border color set to that stock's color.
   - Direction die: Shows "UP ▲", "DOWN ▼", or "DIV ★". Gets a `result-up`, `result-down`, or `result-dividend` class for coloring.
   - Amount die: Shows the cent value (e.g., "10¢").
5. Dice message appears below with a description of what happened, colored by event type.

**Multiplayer behavior**: When it's not your turn, the dice area shows a read-only view. The `RollDice` button is hidden or disabled. Dice results from the active player are pushed via the `DiceRolled` subscription and the animation plays for all players.

#### Trade Controls

There is no separate trade panel. Buy/sell controls are integrated directly into the stock cards (see Stock Board above). During the trading phase, each stock card expands to reveal its inline trade controls. A "Done Trading" button sits below the stock board:

```html
<div id="trade-actions" class="trade-actions hidden">
  <button id="end-turn-btn" class="btn btn-primary btn-large">Done Trading</button>
</div>
```

The `trade-actions` container is hidden during the rolling phase and shown during trading.

#### Sidebar: Current Player Panel

Shows the active player's cash, net worth, and portfolio.

```html
<div id="current-player-panel" class="panel current-player-panel">
  <div id="current-player-info">
    <div class="current-player-header">
      <span class="current-player-name" style="color: #3B82F6">Russell</span>
      <span class="current-player-turn">Rolling</span>
    </div>
    <div class="player-stats">
      <div class="stat-box">
        <div class="stat-label">Cash</div>
        <div class="stat-value cash">$3,200</div>
      </div>
      <div class="stat-box">
        <div class="stat-label">Net Worth</div>
        <div class="stat-value">$7,450</div>
      </div>
    </div>
  </div>
  <div id="current-player-portfolio">
    <div class="portfolio-title">Portfolio</div>
    <div class="portfolio-item">
      <span class="portfolio-stock-name" style="color: #F59E0B">GOLD</span>
      <span class="portfolio-shares">1,500 shares</span>
      <span class="portfolio-value">$1,800</span>
    </div>
    <!-- more holdings... -->
  </div>
</div>
```

- Panel border color is set to the active player's color.
- In the prototype, this shows the active player. In multiplayer, this should always show YOUR portfolio (the logged-in user), not the active player. The phase label changes to indicate whether it's your turn or not.
- "No stocks held" message when portfolio is empty.

#### Sidebar: Scoreboard

Ranked leaderboard of all players by net worth.

```html
<div class="panel scoreboard-panel">
  <h3 class="panel-title">Standings</h3>
  <div id="scoreboard">
    <div class="scoreboard-entry">
      <span class="scoreboard-rank">1</span>
      <span class="scoreboard-name active" style="color: #3B82F6">Russell</span>
      <span class="scoreboard-worth">$7,450</span>
      <div class="scoreboard-bar-container">
        <div
          class="scoreboard-bar"
          style="width: 100%; background: #3B82F6"
        ></div>
      </div>
    </div>
    <!-- more entries... -->
  </div>
</div>
```

- Sorted by net worth descending.
- Active player's name gets the `.active` class and is rendered in their player color.
- Bar width is proportional to the max net worth across all players.
- Bar color matches the player's color.
- In multiplayer, add a subtle online/offline dot next to each player name.

#### Sidebar: Chat Panel (new for multiplayer)

Not in the prototype. Added below the scoreboard.

```html
<div class="panel chat-panel">
  <h3 class="panel-title">Chat</h3>
  <div id="chat-messages" class="chat-messages">
    <div class="chat-message">
      <span class="chat-author" style="color: #EF4444">Alex</span>
      <span class="chat-text">nice split!</span>
    </div>
    <!-- more messages -->
  </div>
  <div class="chat-input-row">
    <input
      type="text"
      id="chat-input"
      placeholder="Type a message..."
      maxlength="200"
    />
    <button id="chat-send-btn" class="btn btn-small">Send</button>
  </div>
</div>
```

- Messages scroll, newest at bottom, auto-scroll on new messages.
- Author name in their player color.
- Input sends via the `SendMessage` mutation; new messages arrive via `MessageReceived` subscription.

### Screen 5: Results Screen

Shown when the game ends (timer expires or manual end in local mode).

```html
<div id="results-screen" class="screen">
  <div class="results-container">
    <div class="results-trophy">&#127942;</div>
    <h1>Game Over</h1>
    <div id="results-list" class="results-list">
      <div class="result-entry">
        <span class="result-rank">&#129351;</span>
        <!-- gold medal emoji -->
        <div class="result-info">
          <div class="result-name" style="color: #3B82F6">Russell</div>
          <div class="result-detail">+$3,200 (+64%) return</div>
        </div>
        <span class="result-worth">$8,200</span>
      </div>
      <!-- more entries... -->
    </div>
    <button id="play-again-btn" class="btn btn-primary btn-large">
      Play Again
    </button>
  </div>
</div>
```

- Trophy emoji at top.
- Players sorted by final net worth descending.
- Rank 1/2/3 use medal emojis. Rank 4+ use numeric.
- Each entry shows player name (in their color), profit/loss amount and percentage, and final net worth.
- "Play Again" returns to setup (local) or lobby (multiplayer).
- In multiplayer, add a "Back to Lobby" button alongside "Play Again".

---

## Toast Notifications

Floating notification that appears briefly for important events (splits, crashes, dividends).

```html
<div class="toast split-toast show">Stock Split! Gold shares doubled!</div>
```

- Created dynamically, appended to `<body>`.
- Types: `split-toast`, `crash-toast`, `dividend-toast`.
- Appears with a slide-in animation (`.show` class triggers CSS transition).
- Auto-dismisses after 2500ms with a fade-out (300ms transition after removing `.show`).
- Only one toast at a time (removes existing toast before creating new).

---

## Key Interaction Patterns

### Phase Toggling

The dice area and stock card trade controls swap visibility based on the current phase:

- **Rolling phase**: `dice-area` visible below the stock board. Stock cards show market data only (no trade controls). `trade-actions` has `.hidden` class.
- **Trading phase**: `dice-area` has `.hidden` class. Each stock card gains the `.trading` class and expands to reveal inline buy/sell controls (`.stock-card-trade`). `trade-actions` is visible, showing the "Done Trading" button below the board.

### Render Cycle

The `render()` function re-renders all dynamic components on every state change. Components:

1. `renderStockBoard()` -- 6 stock cards in a 1x6 row with prices, changes, sparklines. During trading phase, cards expand to include inline buy/sell controls.
2. `renderPhaseBanner()` -- Phase name, active player, progress.
3. `renderDiceArea()` -- Show dice below stock board during rolling phase; hide during trading.
4. `renderPlayerPanel()` -- Active player's cash, net worth, portfolio.
5. `renderScoreboard()` -- All players ranked by net worth.
6. `renderEventTicker()` -- Scrolling event feed.
7. `renderRoundDisplay()` -- Round number badge.

In the multiplayer version, most of these will re-render in response to GraphQL subscription events rather than local state changes.

### Number Formatting

- **Prices** (stock prices, amounts): `$X.XX` format, always 2 decimal places. Stored internally as cents (integer). Displayed via `(cents / 100).toFixed(2)`.
- **Money** (cash, net worth, costs): `$X,XXX` format with thousand separators, no decimals. Uses `toLocaleString('en-US')`.
- **Shares**: Displayed with thousand separators (e.g., "1,500 shares").

---

## Responsive Considerations

The game screen uses a two-column layout (`game-main` + `game-sidebar`). The stock board is a 1x6 horizontal grid that spans the full main content width.

- **Desktop (1200px+)**: Two-column layout. 1x6 stock card row. Chat panel in sidebar below scoreboard. Cards have room for market data + inline trade controls.
- **Tablet (768-1199px)**: Sidebar collapses below the main content. Stock board becomes a 3x2 grid to fit the narrower width while keeping cards readable. Portfolio, scoreboard, and chat stack vertically.
- **Mobile (<768px)**: Single column. Stock board becomes a 2x3 grid or a vertical scrolling 1-column stack. Chat in a slide-out drawer (toggle button in header). Trade controls still appear inline on cards during trading phase.

---

## CSS Class Reference

Full list of CSS classes used across all components, for creating `style.css`:

**Layout**: `screen`, `active`, `hidden`, `setup-container`, `game-layout`, `game-main`, `game-sidebar`, `panel`, `results-container`

**Setup**: `setup-logo`, `logo-icon`, `setup-subtitle`, `setup-players`, `player-input-row`, `player-number`, `player-color-1` through `player-color-4`

**Header**: `game-header`, `header-left`, `header-right`, `game-title`, `round-badge`, `clock-badge`

**Event ticker**: `event-ticker`, `event-ticker-content`, `event-item`, `event-item.up`, `.down`, `.dividend`, `.split`, `.crash`, `.trade`

**Phase banner**: `phase-banner`, `phase-rolling`, `phase-trading`, `phase-label`, `phase-detail`, `phase-player`

**Stock board**: `stock-board`, `stock-card`, `stock-card.trading`, `stock-name`, `stock-price`, `stock-change`, `stock-change.up`, `.down`, `.flat`, `stock-sparkline`, `stock-card-trade`, `flash-up`, `flash-down`, `flash-dividend`

**Dice**: `dice-area`, `dice-container`, `die`, `die-label`, `die-value`, `rolling`, `result-up`, `result-down`, `result-dividend`, `dice-message`, `dice-message.up`, `.down`, `.dividend`, `.split`, `.crash`, `roll-btn`

**Trade controls** (inline on stock cards): `trade-actions`, `trade-holdings`, `trade-lot-cost`, `trade-quick-row`, `trade-row-label`, `buy-label`, `sell-label`, `quick-btn-group`, `quick-btn`, `quick-buy`, `quick-sell`, `quick-max`, `quick-btn-empty`

**Player panel**: `current-player-panel`, `current-player-header`, `current-player-name`, `current-player-turn`, `player-stats`, `stat-box`, `stat-label`, `stat-value`, `stat-value.cash`, `portfolio-title`, `portfolio-empty`, `portfolio-item`, `portfolio-stock-name`, `portfolio-shares`, `portfolio-value`

**Scoreboard**: `scoreboard-panel`, `panel-title`, `scoreboard-entry`, `scoreboard-rank`, `scoreboard-name`, `scoreboard-name.active`, `scoreboard-worth`, `scoreboard-bar-container`, `scoreboard-bar`

**Chat** (new): `chat-panel`, `chat-messages`, `chat-message`, `chat-author`, `chat-text`, `chat-input-row`

**Results**: `results-trophy`, `results-list`, `result-entry`, `result-rank`, `result-info`, `result-name`, `result-detail`, `result-worth`

**Buttons**: `btn`, `btn-primary`, `btn-danger`, `btn-ghost`, `btn-small`, `btn-large`

**Toast**: `toast`, `show`, `split-toast`, `crash-toast`, `dividend-toast`
