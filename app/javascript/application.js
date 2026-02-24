import GameClient from "game_client";

document.addEventListener("DOMContentLoaded", () => {
  const app = document.getElementById("app");
  if (!app) return;

  const userId = app.dataset.userId;
  const userName = app.dataset.userName;

  const client = new GameClient({ userId, userName });
  client.init();
});
