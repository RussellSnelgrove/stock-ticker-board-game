const PLAYER_FIELDS = `
  id turnPosition status online cash currentNetWorth netWorth finalRank
  user { id displayName }
  holdings { quantity value gameStock { id } }
`

const DICE_ROLL_FIELDS = `id direction amount turnNumber stockRolled { name symbol } player { id }`

export const GAME = `
  query Game($id: ID!) {
    game(id: $id) {
      id name inviteCode status duration currentTurn endsAt secondsRemaining rollsRemainingThisTurn solo
      host { id displayName }
      activePlayer { id }
      viewer { id }
      gameStocks { id currentPrice stock { name symbol } }
      players { ${PLAYER_FIELDS} }
      leaderboard { id }
      lastDiceRoll { ${DICE_ROLL_FIELDS} }
      messages { id body createdAt user { id displayName } }
    }
  }
`

export const GAMES = `
  query Games {
    games { id name inviteCode status duration host { displayName } players { id status } }
  }
`

export const CREATE_GAME = `
  mutation CreateGame($name: String!, $duration: Int!) {
    createGame(input: { name: $name, duration: $duration }) { game { id } errors }
  }
`

export const JOIN_GAME = `
  mutation JoinGame($inviteCode: String!) {
    joinGame(input: { inviteCode: $inviteCode }) { game { id } errors }
  }
`

const gameAction = (field) => `
  mutation($gameId: ID!) { ${field}(input: { gameId: $gameId }) { errors } }
`

export const START_GAME = gameAction("startGame")
export const LEAVE_GAME = gameAction("leaveGame")
export const PAUSE_GAME = gameAction("pauseGame")
export const RESUME_GAME = gameAction("resumeGame")
export const END_TURN = gameAction("endTurn")

const ROLL_FIELDS = `outcome previousPrice newPrice rollsRemaining gameStock { id } diceRoll { ${DICE_ROLL_FIELDS} }`

export const ROLL_DICE = `
  mutation RollDice($gameId: ID!) {
    rollDice(input: { gameId: $gameId }) { roll { ${ROLL_FIELDS} } errors }
  }
`

const tradeMutation = (field) => `
  mutation($gameId: ID!, $gameStockId: ID!, $quantity: Int!) {
    ${field}(input: { gameId: $gameId, gameStockId: $gameStockId, quantity: $quantity }) { errors }
  }
`
export const BUY_SHARES = tradeMutation("buyShares")
export const SELL_SHARES = tradeMutation("sellShares")

export const SEND_MESSAGE = `
  mutation SendMessage($gameId: ID!, $body: String!) {
    sendMessage(input: { gameId: $gameId, body: $body }) { errors }
  }
`

export const SUBSCRIPTIONS = {
  gameStarted: `subscription($gameId: ID!) { gameStarted(gameId: $gameId) { game { id } } }`,
  diceRolled: `subscription($gameId: ID!) { diceRolled(gameId: $gameId) { roll { ${ROLL_FIELDS} } } }`,
  gameStockPriceUpdated: `subscription($gameId: ID!) { gameStockPriceUpdated(gameId: $gameId) { gameStock { id currentPrice } previousPrice } }`,
  leaderboardUpdated: `subscription($gameId: ID!) {
    leaderboardUpdated(gameId: $gameId) {
      players { id }
      transaction { transactionType quantity player { user { displayName } } gameStock { stock { name symbol } } }
    }
  }`,
  turnChanged: `subscription($gameId: ID!) { turnChanged(gameId: $gameId) { activePlayer { id } } }`,
  playerPresenceChanged: `subscription($gameId: ID!) { playerPresenceChanged(gameId: $gameId) { player { id online status } } }`,
  gameEnded: `subscription($gameId: ID!) { gameEnded(gameId: $gameId) { game { id } } }`,
  messageReceived: `subscription($gameId: ID!) { messageReceived(gameId: $gameId) { message { id body createdAt user { id displayName } } } }`,
}
