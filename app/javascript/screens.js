// Lobby, waiting room, and results screens.
import { playerColor, STARTING_CASH } from "theme"
import { formatMoney, escapeHtml } from "format"

const $ = (id) => document.getElementById(id)

export function showScreen(name) {
  for (const screen of document.querySelectorAll(".screen")) {
    screen.classList.toggle("active", screen.id === `screen-${name}`)
  }
}

export function renderLobby(games) {
  const list = $("game-list")
  if (!games.length) {
    list.innerHTML = `<li class="game-list-empty">No open games yet. Create one!</li>`
    return
  }
  list.innerHTML = games
    .map((game) => {
      const count = game.players.filter((p) => p.status === "ACTIVE").length
      const status = game.status === "IN_PROGRESS" ? "In progress" : "Waiting"
      return `<li class="game-list-item">
        <div class="game-list-info">
          <span class="game-list-name">${escapeHtml(game.name)}</span>
          <span class="game-list-meta">${count} player${count === 1 ? "" : "s"} · ${game.duration} min · host ${escapeHtml(game.host.displayName)} · ${status}</span>
        </div>
        <button type="button" class="btn btn-ghost btn-small" data-join-code="${game.inviteCode}">Join</button>
      </li>`
    })
    .join("")
}

export function renderWaitingRoom(state) {
  const game = state.game
  const isHost = game.viewer && game.players.find((p) => p.id === game.viewer.id)?.user.id === game.host.id
  $("waiting-game-name").textContent = game.name
  $("invite-code-value").textContent = game.inviteCode
  $("duration-badge").textContent = `${game.duration} min`
  $("waiting-player-list").innerHTML = game.players
    .filter((p) => p.status === "ACTIVE")
    .map(
      (p, i) => `<li class="waiting-player-item">
        <span class="waiting-player-number">${i + 1}</span>
        <span class="waiting-player-dot" style="background:${playerColor(p.turnPosition)}"></span>
        <span class="waiting-player-name">${escapeHtml(p.user.displayName)}</span>
        ${p.user.id === game.host.id ? '<span class="waiting-player-host">(host)</span>' : ""}
      </li>`,
    )
    .join("")
  $("start-game").hidden = !isHost
  $("leave-waiting").hidden = !!isHost
}

const MEDALS = ["🥇", "🥈", "🥉"]

export function renderResults(state) {
  const game = state.game
  // Final ranks are shared on ties; the earlier joiner is listed first.
  const players = [...game.players].sort(
    (a, b) => (a.finalRank ?? 99) - (b.finalRank ?? 99) || a.turnPosition - b.turnPosition,
  )
  $("results-list").innerHTML = players
    .map((p) => {
      const worth = p.netWorth ?? p.currentNetWorth
      const profit = worth - STARTING_CASH
      const percent = ((profit / STARTING_CASH) * 100).toFixed(1)
      const rank = p.finalRank ?? "–"
      return `<li class="result-entry">
        <span class="result-rank">${MEDALS[rank - 1] ?? rank}</span>
        <span class="result-name" style="color:${playerColor(p.turnPosition)}">${escapeHtml(p.user.displayName)}</span>
        <span class="result-profit ${profit >= 0 ? "positive" : "negative"}">${profit >= 0 ? "+" : "-"}${formatMoney(Math.abs(profit))} (${percent}%)</span>
        <span class="result-worth mono">${formatMoney(worth)}</span>
      </li>`
    })
    .join("")
  $("back-to-lobby").hidden = game.players.length < 2
}
