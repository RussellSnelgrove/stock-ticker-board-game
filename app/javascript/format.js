// Money is stored in integer cents everywhere.

// Stock prices and amounts: $X.XX
export function formatPrice(cents) {
  return `$${(cents / 100).toFixed(2)}`
}

// Cash, net worth, and costs: $X,XXX (no decimals)
export function formatMoney(cents) {
  const dollars = Math.round(cents / 100)
  const sign = dollars < 0 ? "-" : ""
  return `${sign}$${Math.abs(dollars).toLocaleString("en-US")}`
}

// Signed money change: +$X / -$X
export function formatMoneyChange(cents) {
  return `${cents >= 0 ? "+" : "-"}${formatMoney(Math.abs(cents))}`
}

// Signed price change: +$0.10 / -$0.05
export function formatPriceChange(cents) {
  return `${cents >= 0 ? "+" : "-"}${formatPrice(Math.abs(cents))}`
}

export function formatShares(count) {
  return `${count.toLocaleString("en-US")} shares`
}

export function formatClock(totalSeconds) {
  const seconds = Math.max(0, Math.floor(totalSeconds))
  const minutes = Math.floor(seconds / 60)
  return `${minutes}:${String(seconds % 60).padStart(2, "0")}`
}

export function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c])
}
