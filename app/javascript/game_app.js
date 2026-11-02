// Client state, routing between screens, user actions, and live updates.
import { gql, mutate } from "graphql_client"
import { subscribe } from "cable_client"
import * as Q from "queries"
import { LOT_SIZE } from "theme"
import { showToast } from "toast"
import { animateDice, describeRoll } from "dice_animation"
import { renderBoard, renderClock, flashStock } from "board"
import { showScreen, renderLobby, renderWaitingRoom, renderResults } from "screens"

const MAX_EVENTS = 50
const $ = (id) => document.getElementById(id)

const state = {
  game: null,
  messages: [],
  events: [],
  lastRoll: null,
  priceChanges: {}, // gameStockId → change in cents since that stock last moved
  lastPrices: {}, // gameStockId → last known price
  netWorthBeforeRoll: null, // playerId → net worth just before the latest roll
  netWorthDelta: {},
  shownRollIds: new Set(),
  rollInFlight: false,
  animating: false,
  scrollChat: false,
  unsubscribers: [],
}

export function start() {
  if (!document.querySelector('meta[name="current-user-id"]')) return // name entry screen is server-rendered

  bindLobby()
  bindWaitingRoom()
  bindGame()
  bindResults()
  setInterval(() => state.game && document.getElementById("screen-game").classList.contains("active") && renderClock(state), 1000)

  const gameId = new URLSearchParams(location.hash.slice(1)).get("game")
  gameId ? enterGame(gameId) : showLobby()
}

// Errors ---------------------------------------------------------------------

let errorTimer
function showError(error) {
  const banner = $("error-banner")
  banner.textContent = error.message || String(error)
  banner.hidden = false
  clearTimeout(errorTimer)
  errorTimer = setTimeout(() => (banner.hidden = true), 4000)
}

async function attempt(action) {
  try {
    await action()
  } catch (error) {
    showError(error)
  }
}

// Lobby ----------------------------------------------------------------------

async function showLobby() {
  leaveGameView()
  history.replaceState(null, "", location.pathname)
  showScreen("lobby")
  await attempt(async () => renderLobby((await gql(Q.GAMES)).games))
}

function bindLobby() {
  $("create-game-form").addEventListener("submit", (event) => {
    event.preventDefault()
    const form = new FormData(event.target)
    attempt(async () => {
      const { game } = await mutate(Q.CREATE_GAME, { name: form.get("name"), duration: Number(form.get("duration")) }, "createGame")
      event.target.reset()
      enterGame(game.id)
    })
  })

  $("join-game-form").addEventListener("submit", (event) => {
    event.preventDefault()
    joinByCode(new FormData(event.target).get("inviteCode"))
  })

  $("game-list").addEventListener("click", (event) => {
    const button = event.target.closest("[data-join-code]")
    if (button) joinByCode(button.dataset.joinCode)
  })
}

function joinByCode(code) {
  attempt(async () => {
    const { game } = await mutate(Q.JOIN_GAME, { inviteCode: code.trim().toUpperCase() }, "joinGame")
    enterGame(game.id)
  })
}

// Entering and leaving a game -------------------------------------------------

async function enterGame(gameId) {
  leaveGameView()
  history.replaceState(null, "", `#game=${gameId}`)
  try {
    await refresh(gameId)
  } catch (error) {
    showError(error)
    return showLobby()
  }
  if (!state.game) return showLobby()

  state.messages = state.game.messages
  state.scrollChat = true
  subscribeToGame(gameId)
  route()
}

function leaveGameView() {
  state.unsubscribers.forEach((unsubscribe) => unsubscribe())
  Object.assign(state, {
    game: null, messages: [], events: [], lastRoll: null, priceChanges: {}, lastPrices: {},
    netWorthBeforeRoll: null, netWorthDelta: {}, shownRollIds: new Set(), unsubscribers: [],
  })
  $("stock-board").dataset.gameId = ""
}

// Fetches the game and records what changed since the last fetch.
async function refresh(gameId = state.game?.id) {
  const { game } = await gql(Q.GAME, { id: gameId })
  if (!game) {
    state.game = null
    return
  }
  for (const gameStock of game.gameStocks) {
    const previous = state.lastPrices[gameStock.id]
    if (previous !== undefined && previous !== gameStock.currentPrice) {
      state.priceChanges[gameStock.id] = gameStock.currentPrice - previous
    }
    state.lastPrices[gameStock.id] = gameStock.currentPrice
  }
  if (state.netWorthBeforeRoll) {
    for (const player of game.players) {
      const before = state.netWorthBeforeRoll[player.id]
      state.netWorthDelta[player.id] = before === undefined ? 0 : player.currentNetWorth - before
    }
  }
  state.game = game
}

function route() {
  const status = state.game.status
  if (status === "WAITING") {
    renderWaitingRoom(state)
    showScreen("waiting")
  } else if (status === "COMPLETED") {
    renderResults(state)
    showScreen("results")
  } else {
    renderBoard(state)
    showScreen("game")
  }
}

async function refreshAndRoute() {
  await attempt(async () => {
    await refresh()
    if (state.game) route()
  })
}

// Live updates ---------------------------------------------------------------

function subscribeToGame(gameId) {
  // The first message after subscribing carries no event (subscribe sends no initial payload).
  const on = (name, handler) =>
    state.unsubscribers.push(subscribe(Q.SUBSCRIPTIONS[name], { gameId }, (data) => data[name] && handler(data[name])))

  on("gameStarted", refreshAndRoute)
  on("turnChanged", refreshAndRoute)
  on("playerPresenceChanged", refreshAndRoute)
  on("gameEnded", refreshAndRoute)
  on("diceRolled", ({ roll }) => showRoll(roll))
  on("gameStockPriceUpdated", () => {}) // prices arrive with the refresh that follows each roll
  on("leaderboardUpdated", ({ transaction }) => {
    if (transaction) recordTrade(transaction)
    if (!state.animating) refreshAndRoute()
  })
  on("messageReceived", ({ message }) => {
    if (state.messages.some((m) => m.id === message.id)) return
    state.messages = [...state.messages, message]
    if (state.game) renderBoard(state)
  })
}

function pushEvent(kind, text) {
  state.events = [...state.events, { kind, text }].slice(-MAX_EVENTS)
}

function recordTrade(transaction) {
  const verb = transaction.transactionType === "BUY" ? "bought" : "sold"
  pushEvent("trade", `${transaction.player.user.displayName} ${verb} ${transaction.quantity.toLocaleString("en-US")} ${transaction.gameStock.stock.symbol}`)
}

// Plays a roll once, whether it arrived from our own RollDice call or from the subscription.
async function showRoll(roll) {
  if (state.shownRollIds.has(roll.diceRoll.id)) return
  state.shownRollIds.add(roll.diceRoll.id)

  state.netWorthBeforeRoll = Object.fromEntries(state.game.players.map((p) => [p.id, p.currentNetWorth]))
  state.animating = true
  renderBoard(state)
  await animateDice(roll.diceRoll)
  state.animating = false

  const { kind, text } = describeRoll(roll)
  state.lastRoll = roll
  pushEvent(kind, text)
  const message = $("dice-message")
  message.textContent = text
  message.className = `dice-message ${kind}`
  if (kind === "split") showToast("split", `<strong>Stock split!</strong> ${text}`)
  if (kind === "crash") showToast("crash", `<strong>Crash!</strong> ${text}`)
  if (roll.outcome === "DIVIDEND") showToast("dividend", `<strong>Dividend!</strong> ${text}`)

  await refreshAndRoute()
  flashStock(roll.gameStock.id, kind)
}

// Game board actions -----------------------------------------------------------

function bindGame() {
  const gameId = () => state.game.id

  $("roll-dice").addEventListener("click", () => {
    state.rollInFlight = true
    renderBoard(state)
    attempt(async () => {
      try {
        const { roll } = await mutate(Q.ROLL_DICE, { gameId: gameId() }, "rollDice")
        state.rollInFlight = false
        await showRoll(roll)
      } finally {
        state.rollInFlight = false
        if (state.game) renderBoard(state)
      }
    })
  })

  $("stock-board").addEventListener("click", (event) => {
    const button = event.target.closest("[data-action]")
    if (!button) return
    const card = button.closest(".stock-card")
    const quantity = Number(button.dataset.lots) * LOT_SIZE
    const buying = button.dataset.action === "buy"
    button.disabled = true
    attempt(async () => {
      await mutate(buying ? Q.BUY_SHARES : Q.SELL_SHARES, { gameId: gameId(), gameStockId: card.dataset.stockId, quantity }, buying ? "buyShares" : "sellShares")
      await refreshAndRoute()
    })
  })

  $("done-trading").addEventListener("click", () =>
    attempt(async () => {
      await mutate(Q.END_TURN, { gameId: gameId() }, "endTurn")
      await refreshAndRoute()
    }),
  )

  $("pause-game").addEventListener("click", () =>
    attempt(async () => {
      const paused = state.game.status === "PAUSED"
      await mutate(paused ? Q.RESUME_GAME : Q.PAUSE_GAME, { gameId: gameId() }, paused ? "resumeGame" : "pauseGame")
      await refreshAndRoute()
    }),
  )

  $("leave-game").addEventListener("click", () => leaveGame())

  $("chat-form").addEventListener("submit", (event) => {
    event.preventDefault()
    const input = event.target.elements.body
    const body = input.value.trim()
    if (!body) return
    attempt(async () => {
      await mutate(Q.SEND_MESSAGE, { gameId: gameId(), body }, "sendMessage")
      input.value = ""
      state.scrollChat = true
    })
  })

  $("chat-toggle").addEventListener("click", () => $("chat-panel").classList.toggle("open"))
}

function leaveGame() {
  attempt(async () => {
    await mutate(Q.LEAVE_GAME, { gameId: state.game.id }, "leaveGame")
    showLobby()
  })
}

function bindWaitingRoom() {
  $("copy-invite-code").addEventListener("click", async () => {
    await navigator.clipboard.writeText(state.game.inviteCode)
    $("copy-invite-code").textContent = "Copied"
    setTimeout(() => ($("copy-invite-code").textContent = "Copy"), 1500)
  })
  $("start-game").addEventListener("click", () =>
    attempt(async () => {
      await mutate(Q.START_GAME, { gameId: state.game.id }, "startGame")
      await refreshAndRoute()
    }),
  )
  $("leave-waiting").addEventListener("click", () => leaveGame())
}

function bindResults() {
  $("play-again").addEventListener("click", () => showLobby())
  $("back-to-lobby").addEventListener("click", () => showLobby())
}
