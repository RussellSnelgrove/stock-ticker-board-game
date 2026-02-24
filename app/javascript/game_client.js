const STOCKS_CONFIG = [
  { name: "Gold", symbol: "GOLD", color: "#F59E0B" },
  { name: "Silver", symbol: "SLVR", color: "#94A3B8" },
  { name: "Bonds", symbol: "BNDS", color: "#3B82F6" },
  { name: "Grain", symbol: "GRN", color: "#D97706" },
  { name: "Industrial", symbol: "IND", color: "#EF4444" },
  { name: "Oil", symbol: "OIL", color: "#10B981" },
];

const PLAYER_COLORS = ["#3B82F6", "#EF4444", "#22C55E", "#F59E0B", "#8B5CF6", "#EC4899"];
const LOT_SIZE = 500;
const STARTING_PRICE = 100;
const BUY_PRESETS = [1, 5, 10, 25];
const ROLLS_PER_TURN = 2;

export default class GameClient {
  constructor({ userId, userName }) {
    this.userId = userId;
    this.userName = userName;
    this.game = null;
    this.myPlayer = null;
    this.phase = "rolling";
    this.rollsRemaining = ROLLS_PER_TURN;
    this.events = [];
    this.clockInterval = null;
    this.lastRoll = null;
    this.lastRollEvents = [];
    this.previousNetWorths = {};
  }

  init() {
    this.setupEventHandlers();
    this.loadGames();
  }

  // === GraphQL Helper ===
  async gql(query, variables = {}) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    const res = await fetch("/graphql", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
      body: JSON.stringify({ query, variables }),
    });
    const json = await res.json();
    if (json.errors) console.error("GraphQL errors:", json.errors);
    return json.data;
  }

  // === Screen Management ===
  showScreen(name) {
    document.querySelectorAll(".screen").forEach((s) => s.classList.remove("active"));
    document.getElementById(`${name}-screen`)?.classList.add("active");
  }

  // === Home Screen ===
  async loadGames() {
    const data = await this.gql(`query { games { id name inviteCode status playerCount hostName duration timeRemaining } }`);
    const list = document.getElementById("open-games-list");
    if (!data?.games?.length) {
      list.innerHTML = '<div class="game-list-empty">No open games yet. Create one!</div>';
      return;
    }
    list.innerHTML = data.games
      .map((g) => `
        <div class="game-list-item">
          <div class="game-info">
            <div class="game-name">${g.name}</div>
            <div class="game-meta">${g.playerCount} player${g.playerCount !== 1 ? "s" : ""} · ${g.duration} min · ${g.hostName}</div>
          </div>
          <button class="btn btn-primary btn-small join-listed-game" data-code="${g.inviteCode}">${g.status === "waiting" ? "Join" : "Spectate"}</button>
        </div>`)
      .join("");
  }

  // === Waiting Room ===
  async enterWaitingRoom(game) {
    this.game = game;
    this.showScreen("waiting");
    document.getElementById("waiting-game-name").textContent = game.name;
    document.getElementById("waiting-invite-code").textContent = game.inviteCode;
    document.getElementById("waiting-duration").textContent = `${game.duration} min`;

    const isHost = String(game.hostId) === String(this.userId);
    document.getElementById("start-game-btn").style.display = isHost ? "" : "none";

    this.renderWaitingPlayers(game.players);
  }

  renderWaitingPlayers(players) {
    const list = document.getElementById("waiting-players");
    list.innerHTML = players
      .map((p, i) => `
        <div class="waiting-player-item">
          <span class="waiting-player-number">${i + 1}</span>
          <span class="waiting-player-dot" style="background: ${PLAYER_COLORS[i % PLAYER_COLORS.length]}"></span>
          <span class="waiting-player-name">${p.displayName}</span>
          ${String(p.userId) === String(this.game?.hostId) ? '<span class="waiting-player-host">(host)</span>' : ""}
        </div>`)
      .join("");
  }

  // === Game Screen ===
  async enterGameScreen(game) {
    this.game = game;
    this.myPlayer = game.players.find((p) => String(p.userId) === String(this.userId));
    this.syncPhaseFromServer();
    this._boardInitialized = false;
    this.showScreen("game");
    this.startClock();
    this.render();
  }

  startClock() {
    if (this.clockInterval) clearInterval(this.clockInterval);
    this.clockInterval = setInterval(() => this.updateClock(), 1000);
    this.updateClock();
  }

  updateClock() {
    if (!this.game?.endsAt) { document.getElementById("game-clock").textContent = "--:--"; return; }
    const remaining = Math.max(0, Math.floor((new Date(this.game.endsAt) - Date.now()) / 1000));
    const min = Math.floor(remaining / 60);
    const sec = remaining % 60;
    const el = document.getElementById("game-clock");
    el.textContent = `${min}:${sec.toString().padStart(2, "0")}`;
    el.className = remaining < 60 ? "clock-badge critical" : remaining < 300 ? "clock-badge warning" : "clock-badge";
    if (remaining <= 0) { clearInterval(this.clockInterval); }
  }

  syncPhaseFromServer() {
    const remaining = this.game.rollsRemainingThisTurn ?? ROLLS_PER_TURN;
    this.rollsRemaining = remaining;
    this.phase = remaining <= 0 ? "trading" : "rolling";
  }

  // === Helpers ===
  get canTrade() {
    return this.phase === "trading" && this.rollsRemaining === 0 && this.isMyTurn();
  }

  get rollNumber() {
    return ROLLS_PER_TURN - this.rollsRemaining + 1;
  }

  // === Rendering ===
  render() {
    if (!this.game) return;
    this.renderStockBoard();
    this.renderPhaseBanner();
    this.renderDiceArea();
    this.renderPlayerPanel();
    this.renderScoreboard();
    this.renderRound();
    this.renderGameLog();
  }

  initStockBoard() {
    const board = document.getElementById("stock-board");
    board.innerHTML = "";
    (this.game.gameStocks || []).forEach((gs) => {
      const card = document.createElement("div");
      card.className = "stock-card";
      card.dataset.gs = gs.id;
      card.innerHTML = `
        <div class="stock-name" style="color: ${gs.color}">${gs.name}</div>
        <div class="stock-price"></div>
        <div class="stock-change"></div>
        <div class="stock-card-trade-slot"></div>`;
      board.appendChild(card);
    });
    this._boardInitialized = true;
  }

  renderStockBoard() {
    const board = document.getElementById("stock-board");
    if (!this._boardInitialized || board.children.length === 0) this.initStockBoard();

    (this.game.gameStocks || []).forEach((gs) => {
      const card = board.querySelector(`.stock-card[data-gs="${gs.id}"]`);
      if (!card) return;

      const change = gs.currentPrice - STARTING_PRICE;
      const pct = ((change / STARTING_PRICE) * 100).toFixed(0);
      const cls = change > 0 ? "up" : change < 0 ? "down" : "flat";
      const sign = change > 0 ? "+" : "";

      card.querySelector(".stock-price").textContent = `$${(gs.currentPrice / 100).toFixed(2)}`;
      const changeEl = card.querySelector(".stock-change");
      changeEl.textContent = `${sign}$${(Math.abs(change) / 100).toFixed(2)} (${sign}${pct}%)`;
      changeEl.className = `stock-change ${cls}`;

      const slot = card.querySelector(".stock-card-trade-slot");
      if (this.canTrade) {
        card.classList.add("trading");
        const shares = this.myShares(gs.id);
        const lots = Math.floor(shares / LOT_SIZE);
        const lotCost = Math.round((LOT_SIZE * gs.currentPrice) / 100);
        const maxBuy = lotCost > 0 ? Math.floor(this.myPlayer.cash / lotCost) : 0;

        const buyBtns = BUY_PRESETS.filter((n) => n <= maxBuy)
          .map((n) => `<button class="quick-btn quick-buy" data-gs="${gs.id}" data-action="buy" data-lots="${n}">${n}</button>`)
          .join("");
        const buyMax = maxBuy > 0 && !BUY_PRESETS.includes(maxBuy) ? `<button class="quick-btn quick-buy quick-max" data-gs="${gs.id}" data-action="buy" data-lots="${maxBuy}">Max(${maxBuy})</button>` : "";
        const sellBtns = BUY_PRESETS.filter((n) => n <= lots)
          .map((n) => `<button class="quick-btn quick-sell" data-gs="${gs.id}" data-action="sell" data-lots="${n}">${n}</button>`)
          .join("");
        const sellAll = lots > 0 && !BUY_PRESETS.includes(lots) ? `<button class="quick-btn quick-sell quick-max" data-gs="${gs.id}" data-action="sell" data-lots="${lots}">All(${lots})</button>` : "";

        slot.innerHTML = `
          <div class="stock-card-trade">
            <div class="trade-holdings">
              <span>${lots > 0 ? `${lots} lot${lots > 1 ? "s" : ""} (${shares.toLocaleString()})` : "No shares"}</span>
              ${lotCost > 0 ? `<span class="trade-lot-cost">$${lotCost}/lot</span>` : ""}
            </div>
            <div class="trade-quick-row"><span class="trade-row-label buy-label">Buy</span><div class="quick-btn-group">${buyBtns}${buyMax}${maxBuy === 0 ? '<span class="quick-btn-empty">—</span>' : ""}</div></div>
            <div class="trade-quick-row"><span class="trade-row-label sell-label">Sell</span><div class="quick-btn-group">${sellBtns}${sellAll}${lots === 0 ? '<span class="quick-btn-empty">—</span>' : ""}</div></div>
          </div>`;
      } else {
        card.classList.remove("trading");
        slot.innerHTML = "";
      }
    });

    const tradeActions = document.getElementById("trade-actions");
    if (this.canTrade) tradeActions.classList.remove("hidden"); else tradeActions.classList.add("hidden");
  }

  renderPhaseBanner() {
    const banner = document.getElementById("phase-banner");
    const active = this.game.activePlayer;
    const color = this.playerColor(active);
    const name = active?.displayName || "Unknown";

    if (this.phase === "rolling") {
      banner.className = "phase-banner phase-rolling";
      banner.innerHTML = `<span class="phase-label">Rolling</span><span class="phase-detail"><span class="phase-player" style="color:${color}">${name}</span> — Roll ${this.rollNumber} of ${ROLLS_PER_TURN}</span>`;
    } else {
      banner.className = "phase-banner phase-trading";
      banner.innerHTML = `<span class="phase-label">Trading</span><span class="phase-detail"><span class="phase-player" style="color:${color}">${name}</span> — Buy & Sell</span>`;
    }
  }

  renderDiceArea() {
    const area = document.getElementById("dice-area");
    const rollBtn = document.getElementById("roll-btn");
    const isMyTurn = this.isMyTurn();

    if (this.phase === "trading") {
      area.classList.add("hidden");
    } else if (this.rollsRemaining > 0 && isMyTurn) {
      area.classList.remove("hidden");
      rollBtn.disabled = false;
      rollBtn.textContent = `Roll Dice (${this.rollNumber} of ${ROLLS_PER_TURN})`;
    } else if (this.rollsRemaining > 0 && !isMyTurn) {
      area.classList.remove("hidden");
      rollBtn.disabled = true;
      rollBtn.textContent = "Waiting...";
    } else {
      area.classList.add("hidden");
    }
  }

  renderPlayerPanel() {
    if (!this.myPlayer) return;
    const panel = document.getElementById("current-player-panel");
    const color = this.playerColor(this.myPlayer);
    panel.style.borderColor = color;

    const info = document.getElementById("current-player-info");
    let phaseLabel = "Watching";
    if (this.isMyTurn()) {
      phaseLabel = this.phase === "rolling" ? `Rolling (${this.rollNumber}/${ROLLS_PER_TURN})` : "Trading";
    }
    info.innerHTML = `
      <div class="current-player-header">
        <span class="current-player-name" style="color:${color}">${this.myPlayer.displayName}</span>
        <span class="current-player-turn">${phaseLabel}</span>
      </div>
      <div class="player-stats">
        <div class="stat-box"><div class="stat-label">Cash</div><div class="stat-value cash">$${this.myPlayer.cash.toLocaleString()}</div></div>
        <div class="stat-box"><div class="stat-label">Net Worth</div><div class="stat-value">$${this.myPlayer.netWorth.toLocaleString()}</div></div>
      </div>`;

    const portfolio = document.getElementById("current-player-portfolio");
    const holdings = (this.myPlayer.holdings || []).filter((h) => h.quantity > 0);
    if (!holdings.length) {
      portfolio.innerHTML = `<div class="portfolio-title">Portfolio</div><div class="portfolio-empty">No stocks held</div>`;
    } else {
      portfolio.innerHTML = `<div class="portfolio-title">Portfolio</div>` +
        holdings.map((h) => `
          <div class="portfolio-item">
            <span class="portfolio-stock-name" style="color:${h.gameStock.color}">${h.gameStock.symbol}</span>
            <span class="portfolio-shares">${h.quantity.toLocaleString()} shares</span>
            <span class="portfolio-value">$${h.value.toLocaleString()}</span>
          </div>`).join("");
    }
  }

  renderScoreboard() {
    const container = document.getElementById("scoreboard");
    const sorted = [...(this.game.players || [])].sort((a, b) => b.netWorth - a.netWorth);
    const max = Math.max(...sorted.map((s) => s.netWorth), 1);

    container.innerHTML = sorted
      .map((p, i) => {
        const color = this.playerColor(p);
        const isMe = String(p.userId) === String(this.userId);
        return `
          <div class="scoreboard-entry">
            <span class="scoreboard-rank">${i + 1}</span>
            <span class="scoreboard-name ${isMe ? "active" : ""}" style="${isMe ? `color:${color}` : ""}">${p.displayName}</span>
            <span class="scoreboard-worth">$${p.netWorth.toLocaleString()}</span>
            <div class="scoreboard-bar-container"><div class="scoreboard-bar" style="width:${(p.netWorth / max) * 100}%;background:${color}"></div></div>
          </div>`;
      })
      .join("");
  }

  renderRound() {
    document.getElementById("round-display").textContent = `Turn ${this.game.currentTurn || 0}`;
  }

  snapshotNetWorths() {
    const snap = {};
    (this.game.players || []).forEach((p) => { snap[p.userId] = p.netWorth; });
    this.previousNetWorths = snap;
  }

  renderGameLog() {
    const rollEl = document.getElementById("last-roll");
    if (this.lastRoll) {
      const r = this.lastRoll;
      const stockConf = STOCKS_CONFIG.find((s) => s.symbol === r.stock.symbol) || STOCKS_CONFIG[0];
      const dirLabel = { up: "UP", down: "DOWN", dividend: "DIV" }[r.direction];
      const dirClass = `die-${r.direction}`;

      const messagesHtml = this.lastRollEvents
        .map((ev) => `<div class="last-roll-message ${ev.eventType}">${ev.message}</div>`)
        .join("");

      rollEl.innerHTML = `
        <div class="last-roll-result">
          <div class="last-roll-dice">
            <span class="last-roll-die" style="border-color:${stockConf.color};color:${stockConf.color}">${r.stock.symbol}</span>
            <span class="last-roll-die ${dirClass}">${dirLabel}</span>
            <span class="last-roll-die">${r.amount}¢</span>
          </div>
          ${messagesHtml}
        </div>`;
    }

    const tracker = document.getElementById("net-worth-tracker");
    const players = [...(this.game.players || [])].sort((a, b) => b.netWorth - a.netWorth);
    const maxNw = Math.max(...players.map((p) => p.netWorth), 1);

    tracker.innerHTML = players
      .map((p) => {
        const color = this.playerColor(p);
        const prev = this.previousNetWorths[p.userId] ?? p.netWorth;
        const diff = p.netWorth - prev;
        const diffStr = diff > 0 ? `+$${diff.toLocaleString()}` : diff < 0 ? `-$${Math.abs(diff).toLocaleString()}` : "—";
        const diffClass = diff > 0 ? "positive" : diff < 0 ? "negative" : "neutral";
        const isMe = String(p.userId) === String(this.userId);

        return `
          <div class="nw-entry">
            <span class="nw-name" style="${isMe ? `color:${color}` : ""}">${p.displayName}</span>
            <span class="nw-values">
              <span class="nw-current">$${p.netWorth.toLocaleString()}</span>
              <span class="nw-change ${diffClass}">${diffStr}</span>
            </span>
          </div>
          <div class="nw-bar" style="width:${(p.netWorth / maxNw) * 100}%;background:${color}"></div>`;
      })
      .join("");
  }

  addEvent(text, type) {
    this.events.unshift({ text, type });
    if (this.events.length > 50) this.events.pop();
    const content = document.getElementById("event-ticker-content");
    const items = this.events.slice(0, 20).map((e) => `<span class="event-item ${e.type}">${e.text}</span>`).join("");
    content.innerHTML = items + items;
  }

  showToast(message, type) {
    document.querySelector(".toast")?.remove();
    const toast = document.createElement("div");
    toast.className = `toast ${type}-toast`;
    toast.textContent = message;
    document.body.appendChild(toast);
    requestAnimationFrame(() => toast.classList.add("show"));
    setTimeout(() => { toast.classList.remove("show"); setTimeout(() => toast.remove(), 300); }, 2500);
  }

  isMyTurn() {
    return this.game?.activePlayer && String(this.game.activePlayer.userId) === String(this.userId);
  }

  myShares(gameStockId) {
    const h = (this.myPlayer?.holdings || []).find((h) => String(h.gameStock.id) === String(gameStockId));
    return h?.quantity || 0;
  }

  playerColor(player) {
    if (!player) return "#64748B";
    const pos = player.turnPosition ?? 0;
    return PLAYER_COLORS[pos % PLAYER_COLORS.length];
  }

  flashCard(gameStockId, type) {
    const card = document.querySelector(`.stock-card[data-gs="${gameStockId}"]`);
    if (!card) return;
    card.classList.remove("flash-up", "flash-down", "flash-dividend");
    void card.offsetWidth;
    card.classList.add(`flash-${type}`);
    setTimeout(() => card.classList.remove(`flash-${type}`), 600);
  }

  // === Dice Animation ===
  animateDice(callback) {
    const dies = ["die-stock", "die-direction", "die-amount"];
    dies.forEach((id) => document.getElementById(id).classList.add("rolling"));
    document.getElementById("roll-btn").disabled = true;

    let ticks = 0;
    const iv = setInterval(() => {
      document.querySelector("#die-stock .die-value").textContent = STOCKS_CONFIG[Math.floor(Math.random() * 6)].symbol;
      document.querySelector("#die-direction .die-value").textContent = ["UP", "DOWN", "DIV"][Math.floor(Math.random() * 3)];
      document.querySelector("#die-amount .die-value").textContent = [5, 10, 20][Math.floor(Math.random() * 3)] + "¢";
      ticks++;
      if (ticks >= 15) { clearInterval(iv); callback(); }
    }, 80);
  }

  showDiceResult(roll) {
    ["die-stock", "die-direction", "die-amount"].forEach((id) => document.getElementById(id).classList.remove("rolling"));
    const stockConf = STOCKS_CONFIG.find((s) => s.symbol === roll.stock.symbol) || STOCKS_CONFIG[0];
    const dieStock = document.getElementById("die-stock");
    dieStock.querySelector(".die-value").textContent = roll.stock.symbol;
    dieStock.style.borderColor = stockConf.color;

    const dirMap = { up: "UP ▲", down: "DOWN ▼", dividend: "DIV ★" };
    const dieDir = document.getElementById("die-direction");
    dieDir.querySelector(".die-value").textContent = dirMap[roll.direction];
    dieDir.className = `die result-${roll.direction}`;

    document.querySelector("#die-amount .die-value").textContent = roll.amount + "¢";
  }

  // === Refresh Game State ===
  async refreshGame() {
    if (!this.game) return;
    const data = await this.gql(`query($id: ID!) {
      game(id: $id) {
        id name inviteCode status currentTurn duration startsAt endsAt timeRemaining hostId hostName rollsRemainingThisTurn
        players { id userId displayName cash status turnPosition netWorth holdings { id quantity lots value gameStock { id currentPrice name symbol color } } }
        gameStocks { id currentPrice priceDollars name symbol color lotCost stock { id name symbol color } }
        activePlayer { id userId displayName turnPosition }
        playerCount
      }
    }`, { id: this.game.id });

    if (data?.game) {
      this.game = data.game;
      this.myPlayer = this.game.players.find((p) => String(p.userId) === String(this.userId));
    }
  }

  // === Event Handlers ===
  setupEventHandlers() {
    // Create game
    document.getElementById("create-game-btn")?.addEventListener("click", async () => {
      const name = document.getElementById("game-name-input").value.trim() || `${this.userName}'s Game`;
      const duration = parseInt(document.getElementById("game-duration-select").value);
      const data = await this.gql(`mutation($name: String!, $duration: Int!) { createGame(input: { name: $name, duration: $duration }) { game { id name inviteCode status duration hostId players { id userId displayName turnPosition } } errors } }`, { name, duration });
      if (data?.createGame?.errors?.length) { alert(data.createGame.errors.join(", ")); return; }
      if (data?.createGame?.game) this.enterWaitingRoom(data.createGame.game);
    });

    // Join by code
    document.getElementById("join-game-btn")?.addEventListener("click", async () => {
      const code = document.getElementById("invite-code-input").value.trim();
      if (!code) return;
      await this.joinByCode(code);
    });

    // Join from game list
    document.addEventListener("click", (e) => {
      const btn = e.target.closest(".join-listed-game");
      if (btn) this.joinByCode(btn.dataset.code);
    });

    // Start game (host)
    document.getElementById("start-game-btn")?.addEventListener("click", async () => {
      if (!this.game) return;
      const data = await this.gql(`mutation($id: ID!) { startGame(input: { gameId: $id }) { game { id name inviteCode status currentTurn duration startsAt endsAt timeRemaining hostId hostName rollsRemainingThisTurn players { id userId displayName cash status turnPosition netWorth holdings { id quantity lots value gameStock { id currentPrice name symbol color } } } gameStocks { id currentPrice priceDollars name symbol color lotCost stock { id name symbol color } } activePlayer { id userId displayName turnPosition } playerCount } errors } }`, { id: this.game.id });
      if (data?.startGame?.errors?.length) { alert(data.startGame.errors.join(", ")); return; }
      if (data?.startGame?.game) this.enterGameScreen(data.startGame.game);
    });

    // Leave waiting room
    document.getElementById("leave-waiting-btn")?.addEventListener("click", async () => {
      if (!this.game) return;
      await this.gql(`mutation($id: ID!) { leaveGame(input: { gameId: $id }) { errors } }`, { id: this.game.id });
      this.game = null;
      this.showScreen("home");
      this.loadGames();
    });

    // Copy invite code
    document.getElementById("copy-code-btn")?.addEventListener("click", () => {
      const code = document.getElementById("waiting-invite-code").textContent;
      navigator.clipboard.writeText(code);
    });

    // Roll dice
    document.getElementById("roll-btn")?.addEventListener("click", () => {
      if (!this.isMyTurn() || this.rollsRemaining <= 0) return;
      this.snapshotNetWorths();
      this.animateDice(async () => {
        const data = await this.gql(`mutation($id: ID!) { rollDice(input: { gameId: $id }) { diceRoll { id stock { id name symbol color } direction amount turnNumber } events { eventType stockSymbol message } rollsRemaining game { id currentTurn gameStocks { id currentPrice name symbol color lotCost } activePlayer { id userId displayName turnPosition } players { id userId displayName cash status turnPosition netWorth holdings { id quantity lots value gameStock { id currentPrice name symbol color } } } } errors } }`, { id: this.game.id });

        if (data?.rollDice?.errors?.length) { alert(data.rollDice.errors.join(", ")); return; }
        if (data?.rollDice?.diceRoll) {
          this.showDiceResult(data.rollDice.diceRoll);
          this.lastRoll = data.rollDice.diceRoll;
          this.lastRollEvents = data.rollDice.events || [];
          this.rollsRemaining = data.rollDice.rollsRemaining;
          if (this.rollsRemaining <= 0) {
            this.phase = "trading";
          }
        }
        if (data?.rollDice?.game) {
          Object.assign(this.game, data.rollDice.game);
          this.myPlayer = this.game.players.find((p) => String(p.userId) === String(this.userId));
        }
        (data?.rollDice?.events || []).forEach((ev) => {
          this.addEvent(ev.message, ev.eventType);
          if (ev.eventType === "split") this.showToast(ev.message, "split");
          if (ev.eventType === "crash") this.showToast(ev.message, "crash");
          if (ev.eventType === "dividend" && ev.message.includes("receives")) this.showToast(ev.message, "dividend");
        });
        this.render();
      });
    });

    // Buy/Sell (delegated on stock board)
    document.getElementById("stock-board")?.addEventListener("click", async (e) => {
      const btn = e.target.closest(".quick-btn");
      if (!btn || !this.canTrade) return;
      const gsId = btn.dataset.gs;
      const action = btn.dataset.action;
      const lots = parseInt(btn.dataset.lots);

      const mutation = action === "buy"
        ? `mutation($gid: ID!, $gsid: ID!, $l: Int!) { buyShares(input: { gameId: $gid, gameStockId: $gsid, lots: $l }) { player { id cash netWorth holdings { id quantity lots value gameStock { id currentPrice name symbol color } } } errors } }`
        : `mutation($gid: ID!, $gsid: ID!, $l: Int!) { sellShares(input: { gameId: $gid, gameStockId: $gsid, lots: $l }) { player { id cash netWorth holdings { id quantity lots value gameStock { id currentPrice name symbol color } } } errors } }`;

      const data = await this.gql(mutation, { gid: this.game.id, gsid: gsId, l: lots });
      const result = action === "buy" ? data?.buyShares : data?.sellShares;

      if (result?.errors?.length) { alert(result.errors.join(", ")); return; }
      if (result?.player) {
        this.myPlayer = { ...this.myPlayer, ...result.player };
        const idx = this.game.players.findIndex((p) => String(p.userId) === String(this.userId));
        if (idx >= 0) this.game.players[idx] = this.myPlayer;
        const gs = this.game.gameStocks.find((g) => String(g.id) === String(gsId));
        const stockName = gs?.name || "Stock";
        this.addEvent(`${this.userName} ${action === "buy" ? "buys" : "sells"} ${lots * LOT_SIZE} ${stockName}`, "trade");
      }
      this.render();
    });

    // End turn
    document.getElementById("end-turn-btn")?.addEventListener("click", async () => {
      if (!this.game) return;
      const data = await this.gql(`mutation($id: ID!) { endTurn(input: { gameId: $id }) { game { id currentTurn rollsRemainingThisTurn activePlayer { id userId displayName turnPosition } players { id userId displayName cash status turnPosition netWorth holdings { id quantity lots value gameStock { id currentPrice name symbol color } } } } errors } }`, { id: this.game.id });
      if (data?.endTurn?.errors?.length) { alert(data.endTurn.errors.join(", ")); return; }
      if (data?.endTurn?.game) {
        Object.assign(this.game, data.endTurn.game);
        this.myPlayer = this.game.players.find((p) => String(p.userId) === String(this.userId));
      }
      this.syncPhaseFromServer();
      this.resetDice();
      this.render();
    });

    // Chat
    const sendChat = async () => {
      const input = document.getElementById("chat-input");
      const body = input.value.trim();
      if (!body || !this.game) return;
      input.value = "";
      await this.gql(`mutation($gid: ID!, $body: String!) { sendMessage(input: { gameId: $gid, body: $body }) { message { id body authorName } errors } }`, { gid: this.game.id, body });
      this.appendChatMessage(this.userName, body, this.playerColor(this.myPlayer));
    };
    document.getElementById("chat-send-btn")?.addEventListener("click", sendChat);
    document.getElementById("chat-input")?.addEventListener("keydown", (e) => { if (e.key === "Enter") sendChat(); });

    // Pause
    document.getElementById("pause-game-btn")?.addEventListener("click", async () => {
      if (!this.game) return;
      await this.gql(`mutation($id: ID!) { pauseGame(input: { gameId: $id }) { game { id status } errors } }`, { id: this.game.id });
      this.showScreen("home");
      this.loadGames();
    });

    // Back to lobby
    document.getElementById("back-to-lobby-btn")?.addEventListener("click", () => {
      this.game = null;
      this.showScreen("home");
      this.loadGames();
    });
  }

  async joinByCode(code) {
    const data = await this.gql(`mutation($code: String!) { joinGame(input: { inviteCode: $code }) { game { id name inviteCode status currentTurn duration startsAt endsAt timeRemaining hostId hostName rollsRemainingThisTurn players { id userId displayName cash status turnPosition netWorth holdings { id quantity lots value gameStock { id currentPrice name symbol color } } } gameStocks { id currentPrice priceDollars name symbol color lotCost stock { id name symbol color } } activePlayer { id userId displayName turnPosition } playerCount } errors } }`, { code });
    if (data?.joinGame?.errors?.length) { alert(data.joinGame.errors.join(", ")); return; }
    const game = data?.joinGame?.game;
    if (!game) return;
    if (game.status === "waiting") this.enterWaitingRoom(game);
    else if (game.status === "in_progress") this.enterGameScreen(game);
  }

  appendChatMessage(author, text, color = "#94A3B8") {
    const container = document.getElementById("chat-messages");
    const div = document.createElement("div");
    div.className = "chat-message";
    div.innerHTML = `<span class="chat-author" style="color:${color}">${author}</span><span class="chat-text">${text}</span>`;
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
  }

  resetDice() {
    ["die-stock", "die-direction", "die-amount"].forEach((id) => {
      const die = document.getElementById(id);
      die.className = "die";
      die.querySelector(".die-value").textContent = "?";
      die.style.borderColor = "";
    });
    document.getElementById("dice-message").textContent = "";
    document.getElementById("dice-message").className = "dice-message";
  }
}
