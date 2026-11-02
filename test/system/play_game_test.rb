# typed: false
# frozen_string_literal: true

require "application_system_test_case"

class PlayGameTest < ApplicationSystemTestCase
  test "two players join, take a turn, trade, and chat with live updates" do
    code = nil

    using_session(:alice) do
      pick_name "Alice"
      fill_in "name", with: "Friday Market"
      click_on "Create Game"
      assert_selector "#invite-code-value", text: /\A[A-Z0-9]{6}\z/
      code = find("#invite-code-value").text
    end

    using_session(:bob) do
      pick_name "Bob"
      within("#join-game-form") do
        fill_in "inviteCode", with: code
        click_on "Join"
      end
      assert_selector "#waiting-game-name", text: "Friday Market"
      assert_selector ".waiting-player-name", text: "Alice"
      assert_no_selector "#start-game"
    end

    using_session(:alice) do
      assert_selector ".waiting-player-name", text: "Bob" # arrives by subscription
      click_on "Start Game"
      assert_selector "#phase-banner", text: "Roll 1 of 2 · Your turn"
    end

    using_session(:bob) do
      assert_selector "#phase-banner", text: "Roll 1 of 2 · Alice's turn" # arrives by subscription
      assert_no_selector "#roll-dice"
    end

    using_session(:alice) do
      click_on "Roll Dice (1 of 2)"
      assert_selector "#phase-banner", text: "Roll 2 of 2"
      click_on "Roll Dice (2 of 2)"
      assert_selector "#phase-banner", text: "Buy & Sell · Your turn"

      within(".stock-card[data-stock-name='Oil']") { first(".quick-buy").click }
      assert_selector ".holdings-list", text: "OIL"
      click_on "Done Trading"
      assert_selector "#phase-banner", text: "Bob's turn"
    end

    using_session(:bob) do
      assert_selector "#phase-banner", text: "Roll 1 of 2 · Your turn"
      assert_selector "#ticker-track", text: "Alice bought 500 OIL"
      assert_selector ".last-roll-message", text: /\S/
      fill_in "body", with: "Nice trade 📈"
      click_on "Send"
    end

    using_session(:alice) do
      assert_selector "#chat-messages", text: "Bob Nice trade 📈"
    end
  end

  test "a solo player pauses, resumes, and sees the results when the clock runs out" do
    pick_name "Dana"
    fill_in "name", with: "Practice"
    click_on "Create Game"
    click_on "Start Game"
    assert_selector "#phase-banner", text: "Roll 1 of 2 · Your turn"

    click_on "Pause"
    assert_selector "#phase-banner", text: "Paused"
    click_on "Resume"
    assert_selector "#phase-banner", text: "Roll 1 of 2"

    game = Game.find_by!(name: "Practice")
    game.update_columns(ends_at: 1.second.ago)
    GameClockExpiryJob.perform_now(game.id)

    assert_text "Game Over"
    assert_selector ".result-entry", text: "Dana"
    assert_selector ".result-entry", text: "+$0 (0.0%)"
    click_on "Play Again"
    assert_text "Playing as Dana"
  end
end
