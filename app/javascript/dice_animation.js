import { STOCK_ORDER, STOCK_SYMBOLS, STOCK_COLORS } from "theme"
import { formatPrice } from "format"

const TICKS = 15
const TICK_MS = 80
const DIRECTIONS = {
  UP: { label: "UP ▲", className: "result-up" },
  DOWN: { label: "DOWN ▼", className: "result-down" },
  DIVIDEND: { label: "DIV ★", className: "result-dividend" },
}
const AMOUNTS = [5, 10, 20]
const pick = (list) => list[Math.floor(Math.random() * list.length)]

function setDie(id, text, { className = "", color = "" } = {}) {
  const die = document.getElementById(id)
  const value = die.querySelector(".die-value")
  value.textContent = text
  value.className = `die-value ${className}`
  die.style.borderColor = color
}

// Cycles random faces, then lands on the rolled values.
export function animateDice(diceRoll) {
  const dice = ["die-stock", "die-direction", "die-amount"].map((id) => document.getElementById(id))
  dice.forEach((die) => die.classList.add("rolling"))

  return new Promise((resolve) => {
    let tick = 0
    const timer = setInterval(() => {
      tick += 1
      if (tick < TICKS) {
        const stock = pick(STOCK_ORDER)
        setDie("die-stock", STOCK_SYMBOLS[stock], { color: STOCK_COLORS[stock] })
        setDie("die-direction", DIRECTIONS[pick(Object.keys(DIRECTIONS))].label)
        setDie("die-amount", `${pick(AMOUNTS)}¢`)
        return
      }
      clearInterval(timer)
      dice.forEach((die) => die.classList.remove("rolling"))
      showDiceFaces(diceRoll)
      resolve()
    }, TICK_MS)
  })
}

export function showDiceFaces(diceRoll) {
  const name = diceRoll.stockRolled.name
  const direction = DIRECTIONS[diceRoll.direction]
  setDie("die-stock", STOCK_SYMBOLS[name], { color: STOCK_COLORS[name] })
  setDie("die-direction", direction.label, { className: direction.className })
  setDie("die-amount", `${diceRoll.amount}¢`)
}

// A one-line summary of a roll, and the event kind used for colors, ticker, and toasts.
export function describeRoll(roll) {
  const { name } = roll.diceRoll.stockRolled
  const amount = roll.diceRoll.amount
  switch (roll.outcome) {
    case "UP":
      return { kind: "up", text: `${name} up ${amount}¢ to ${formatPrice(roll.newPrice)}` }
    case "DOWN":
      return { kind: "down", text: `${name} down ${amount}¢ to ${formatPrice(roll.newPrice)}` }
    case "SPLIT":
      return { kind: "split", text: `${name} split! Shares doubled, price reset to $1.00` }
    case "WORTHLESS":
      return { kind: "crash", text: `${name} crashed! Shares wiped, price reset to $1.00` }
    case "DIVIDEND":
      return { kind: "dividend", text: `${name} pays a ${amount}% dividend` }
    default:
      return { kind: "dividend", text: `${name} dividend skipped (below $1.00)` }
  }
}
