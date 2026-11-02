// Game board renderers. Each one owns one area of the screen and is safe to call on every state change.
import { STOCK_ORDER, STOCK_COLORS, STOCK_SYMBOLS, LOT_SIZE, QUICK_LOTS, playerColor } from "theme"
import { formatPrice, formatMoney, formatMoneyChange, formatPriceChange, formatShares, formatClock, escapeHtml } from "format"
import { describeRoll } from "dice_animation"

const $ = (id) => document.getElementById(id)

// Facts about the current game that several renderers need.
export function view(state) {
  const game = state.game
  const players = new Map(game.players.map((p) => [p.id, p]))
  const me = game.viewer ? players.get(game.viewer.id) : null
  const running = game.status === "IN_PROGRESS"
  const isMyTurn = running && !!me && game.activePlayer?.id === me.id
  const activePlayer = game.activePlayer ? players.get(game.activePlayer.id) : null
  return {
    game,
    players,
    me,
    running,
    isMyTurn,
    activePlayer,
    rolling: running && game.rollsRemainingThisTurn > 0,
    trading: isMyTurn && game.rollsRemainingThisTurn === 0,
    rollNumber: 3 - game.rollsRemainingThisTurn,
    ranked: game.leaderboard.map((p) => players.get(p.id)),
    stockByName: new Map(game.gameStocks.map((gs) => [gs.stock.name, gs])),
  }
}

function playerName(player, { colored = true } = {}) {
  const name = escapeHtml(player.user.displayName)
  return colored ? `<span style="color:${playerColor(player.turnPosition)}">${name}</span>` : name
}

// Only touch the DOM when the markup actually changed (keeps hover, focus, and CSS animations intact).
function setHtml(element, html) {
  if (element.dataset.html === html) return
  element.dataset.html = html
  element.innerHTML = html
}

// 1. Creates the six cards once. Their positions never change.
export function initStockBoard(state) {
  const board = $("stock-board")
  if (board.dataset.gameId === state.game.id) return
  board.dataset.gameId = state.game.id
  const { stockByName } = view(state)

  board.innerHTML = STOCK_ORDER.map((name) => {
    const gameStock = stockByName.get(name)
    return `
      <div class="stock-card" data-stock-name="${name}" data-stock-id="${gameStock.id}" style="--stock-color:${STOCK_COLORS[name]}">
        <div class="stock-name">${name} <span class="stock-symbol">${STOCK_SYMBOLS[name]}</span></div>
        <div class="stock-price"></div>
        <div class="stock-change"></div>
        <div class="stock-card-trade-slot"></div>
      </div>`
  }).join("")
}

function tradeButtons(action, maxLots, label) {
  if (maxLots < 1) return `<span class="trade-none">—</span>`
  const presets = QUICK_LOTS.filter((lots) => lots <= maxLots)
  const buttons = presets.map(
    (lots) => `<button type="button" class="quick-btn quick-${action}" data-action="${action}" data-lots="${lots}" title="${formatShares(lots * LOT_SIZE)}">${lots}</button>`,
  )
  if (!presets.includes(maxLots)) {
    buttons.push(
      `<button type="button" class="quick-btn quick-${action} quick-max" data-action="${action}" data-lots="${maxLots}" title="${formatShares(maxLots * LOT_SIZE)}">${label}(${maxLots})</button>`,
    )
  }
  return buttons.join("")
}

// 2. Updates prices and changes in place, and fills the trade slots during your trading phase.
export function renderStockBoard(state) {
  const v = view(state)
  for (const card of $("stock-board").children) {
    const gameStock = v.stockByName.get(card.dataset.stockName)
    card.querySelector(".stock-price").textContent = formatPrice(gameStock.currentPrice)

    const change = state.priceChanges[gameStock.id]
    const changeEl = card.querySelector(".stock-change")
    changeEl.textContent = change === undefined ? "—" : formatPriceChange(change)
    changeEl.className = `stock-change ${change > 0 ? "positive" : change < 0 ? "negative" : "neutral"}`

    card.classList.toggle("trading", v.trading)
    const slot = card.querySelector(".stock-card-trade-slot")
    if (!v.trading) {
      setHtml(slot, "")
      continue
    }
    const holding = v.me.holdings.find((h) => h.gameStock.id === gameStock.id)
    const owned = holding?.quantity ?? 0
    const lotCost = gameStock.currentPrice * LOT_SIZE
    setHtml(
      slot,
      `<div class="trade-holdings">${owned ? `${formatShares(owned)} · ${formatMoney(holding.value)}` : "None held"}</div>
       <div class="trade-row"><span class="trade-label">Buy</span>${tradeButtons("buy", Math.floor(v.me.cash / lotCost), "Max")}</div>
       <div class="trade-row"><span class="trade-label">Sell</span>${tradeButtons("sell", owned / LOT_SIZE, "All")}</div>`,
    )
  }
  $("trade-actions").hidden = !v.trading
}

// Briefly highlights the card a roll hit.
export function flashStock(gameStockId, kind) {
  const card = document.querySelector(`.stock-card[data-stock-id="${gameStockId}"]`)
  if (!card) return
  const className = { up: "flash-up", split: "flash-up", down: "flash-down", crash: "flash-down" }[kind] || "flash-dividend"
  card.classList.remove("flash-up", "flash-down", "flash-dividend")
  void card.offsetWidth // restart the animation
  card.classList.add(className)
  setTimeout(() => card.classList.remove(className), 600)
}

// 3. Whose turn it is and what they are doing.
export function renderPhaseBanner(state) {
  const v = view(state)
  const banner = $("phase-banner")
  let phase = "phase-ended"
  let html = "Game over"

  if (v.game.status === "PAUSED") {
    phase = "phase-paused"
    html = "Paused"
  } else if (v.running && !v.activePlayer) {
    phase = "phase-paused"
    html = "Waiting for a player to rejoin"
  } else if (v.running) {
    const who = v.isMyTurn ? "Your turn" : `${playerName(v.activePlayer)}'s turn`
    phase = v.rolling ? "phase-rolling" : "phase-trading"
    html = v.rolling ? `Roll ${v.rollNumber} of 2 · ${who}` : `Buy &amp; Sell · ${who}`
  }
  banner.className = `phase-banner ${phase}`
  setHtml(banner, html)
}

// 4. Dice are shown while rolling and hidden while trading.
export function renderDiceArea(state) {
  const v = view(state)
  $("dice-area").hidden = !v.rolling && !state.animating
  const button = $("roll-dice")
  button.hidden = !(v.isMyTurn && v.rolling)
  button.disabled = state.rollInFlight || state.animating
  button.textContent = `Roll Dice (${v.rollNumber} of 2)`
}

// 5. Your cash, net worth, and holdings.
export function renderPlayerPanel(state) {
  const v = view(state)
  const panel = $("player-panel")
  if (!v.me) {
    setHtml(panel, `<p class="muted">You are watching this game.</p>`)
    return
  }
  panel.style.borderColor = playerColor(v.me.turnPosition)
  const phaseLabel = v.isMyTurn ? (v.rolling ? `Rolling (${v.rollNumber}/2)` : "Trading") : "Watching"
  const stockNames = new Map(v.game.gameStocks.map((gs) => [gs.id, gs.stock.name]))
  const holdings = v.me.holdings.length
    ? v.me.holdings
        .map((h) => {
          const name = stockNames.get(h.gameStock.id)
          return `<li><span style="color:${STOCK_COLORS[name]}">${STOCK_SYMBOLS[name]}</span>
            <span class="mono">${h.quantity.toLocaleString("en-US")}</span>
            <span class="mono">${formatMoney(h.value)}</span></li>`
        })
        .join("")
    : `<li class="muted">No stocks held</li>`

  setHtml(
    panel,
    `<div class="panel-header"><h2>${playerName(v.me)}</h2><span class="phase-label">${phaseLabel}</span></div>
     <div class="stats">
       <div class="stat-box"><span class="stat-label">Cash</span><span class="stat-value cash">${formatMoney(v.me.cash)}</span></div>
       <div class="stat-box"><span class="stat-label">Net Worth</span><span class="stat-value">${formatMoney(v.me.currentNetWorth)}</span></div>
     </div>
     <ul class="holdings-list">${holdings}</ul>`,
  )
}

// 6. All players ranked by net worth.
export function renderScoreboard(state) {
  const v = view(state)
  const max = Math.max(1, ...v.ranked.map((p) => p.currentNetWorth))
  const multiplayer = v.game.players.length > 1
  setHtml(
    $("scoreboard"),
    v.ranked
      .map((p, i) => {
        const active = v.activePlayer?.id === p.id
        const color = playerColor(p.turnPosition)
        const dot = multiplayer ? `<span class="presence-dot ${p.online ? "online" : "offline"}" title="${p.online ? "Online" : "Offline"}"></span>` : ""
        return `<li class="score-entry${active ? " active" : ""}" style="--player-color:${color}">
          <span class="score-rank">${i + 1}</span>
          ${dot}<span class="score-name">${playerName(p, { colored: active })}${p.status === "DROPPED" ? ' <span class="muted">(left)</span>' : ""}</span>
          <span class="score-value mono">${formatMoney(p.currentNetWorth)}</span>
          <span class="score-bar" style="width:${(p.currentNetWorth / max) * 100}%;background:${color}"></span>
        </li>`
      })
      .join(""),
  )
}

// 7. Scrolling market feed. Content is doubled so the CSS loop is seamless.
export function renderEventTicker(state) {
  const items = state.events
    .slice(-20)
    .reverse()
    .map((e) => `<span class="ticker-item ${e.kind}">${escapeHtml(e.text)}</span>`)
    .join("")
  setHtml($("ticker-track"), items ? items + items : `<span class="ticker-item">Waiting for the first roll…</span>`)
}

// 8. Turn number.
export function renderRoundDisplay(state) {
  $("round-badge").textContent = `Turn ${state.game.currentTurn + 1}`
  $("game-title").textContent = state.game.name
}

// 9. Last roll and each player's net worth change since that roll.
export function renderGameLog(state) {
  const v = view(state)
  // After a page load only the dice faces of the last roll are known, not what they did.
  const roll = state.lastRoll ?? (v.game.lastDiceRoll && { diceRoll: v.game.lastDiceRoll })
  if (roll) {
    const { name } = roll.diceRoll.stockRolled
    const direction = { UP: "die-up", DOWN: "die-down", DIVIDEND: "die-dividend" }[roll.diceRoll.direction]
    const { kind, text } = roll.outcome ? describeRoll(roll) : { kind: "", text: "" }
    setHtml(
      $("last-roll-dice"),
      `<span class="last-roll-die" style="color:${STOCK_COLORS[name]}">${STOCK_SYMBOLS[name]}</span>
       <span class="last-roll-die ${direction}">${roll.diceRoll.direction}</span>
       <span class="last-roll-die">${roll.diceRoll.amount}¢</span>`,
    )
    const message = $("last-roll-message")
    message.textContent = text
    message.className = `last-roll-message ${kind}`
  }

  const max = Math.max(1, ...v.ranked.map((p) => p.currentNetWorth))
  setHtml(
    $("net-worth-tracker"),
    v.ranked
      .map((p) => {
        const delta = state.netWorthDelta[p.id]
        const changeClass = !delta ? "neutral" : delta > 0 ? "positive" : "negative"
        const color = playerColor(p.turnPosition)
        return `<div class="nw-entry">
          <span class="nw-name">${playerName(p, { colored: p.id === v.me?.id })}</span>
          <span class="nw-values"><span class="nw-current">${formatMoney(p.currentNetWorth)}</span>
            <span class="nw-change ${changeClass}">${delta ? formatMoneyChange(delta) : "—"}</span></span>
          <span class="nw-bar" style="width:${(p.currentNetWorth / max) * 100}%;background:${color}"></span>
        </div>`
      })
      .join(""),
  )
}

// Chat messages (newest at the bottom) and who is online.
export function renderChat(state) {
  const v = view(state)
  const colorByUser = new Map(v.game.players.map((p) => [p.user.id, playerColor(p.turnPosition)]))
  const list = $("chat-messages")
  const atBottom = list.scrollHeight - list.scrollTop - list.clientHeight < 40
  setHtml(
    list,
    state.messages
      .map(
        (m) => `<li><span class="chat-author" style="color:${colorByUser.get(m.user.id) || "inherit"}">${escapeHtml(m.user.displayName)}</span>
          <span class="chat-body">${escapeHtml(m.body)}</span></li>`,
      )
      .join(""),
  )
  if (atBottom || state.scrollChat) list.scrollTop = list.scrollHeight
  state.scrollChat = false

  const online = v.game.players.filter((p) => p.online && p.status === "ACTIVE")
  setHtml(
    $("chat-online"),
    online.length ? `Online: ${online.map((p) => playerName(p)).join(", ")}` : `<span class="muted">Nobody else online</span>`,
  )
}

// Countdown from endsAt; red under 5 minutes, pulsing under 1 minute.
export function renderClock(state) {
  const game = state.game
  const clock = $("clock-badge")
  let seconds = 0
  if (game.status === "IN_PROGRESS" && game.endsAt) seconds = (new Date(game.endsAt) - Date.now()) / 1000
  else if (game.status === "PAUSED") seconds = game.secondsRemaining ?? 0
  clock.textContent = formatClock(seconds)
  clock.classList.toggle("warning", seconds < 300)
  clock.classList.toggle("critical", seconds < 60 && game.status === "IN_PROGRESS")

  const pause = $("pause-game")
  pause.hidden = !game.solo || !["IN_PROGRESS", "PAUSED"].includes(game.status)
  pause.textContent = game.status === "PAUSED" ? "Resume" : "Pause"
}

export function renderBoard(state) {
  initStockBoard(state)
  renderStockBoard(state)
  renderPhaseBanner(state)
  renderDiceArea(state)
  renderPlayerPanel(state)
  renderScoreboard(state)
  renderEventTicker(state)
  renderRoundDisplay(state)
  renderGameLog(state)
  renderChat(state)
  renderClock(state)
}
