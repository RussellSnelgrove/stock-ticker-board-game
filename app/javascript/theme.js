// Fixed order of the board, left to right.
export const STOCK_ORDER = ["Grain", "Industrial", "Bonds", "Oil", "Silver", "Gold"]

export const STOCK_COLORS = {
  Grain: "#D97706",
  Industrial: "#EF4444",
  Bonds: "#3B82F6",
  Oil: "#10B981",
  Silver: "#94A3B8",
  Gold: "#F59E0B",
}

export const STOCK_SYMBOLS = {
  Grain: "GRN",
  Industrial: "IND",
  Bonds: "BNDS",
  Oil: "OIL",
  Silver: "SLVR",
  Gold: "GOLD",
}

// Assigned by join order; cycles after four players.
export const PLAYER_COLORS = ["#3B82F6", "#EF4444", "#22C55E", "#F59E0B"]

export function playerColor(turnPosition) {
  return PLAYER_COLORS[turnPosition % PLAYER_COLORS.length]
}

export const LOT_SIZE = 500
export const QUICK_LOTS = [1, 5, 10, 25]
export const STARTING_CASH = 500_000
