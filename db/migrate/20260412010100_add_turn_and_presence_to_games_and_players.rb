# typed: false
# frozen_string_literal: true

class AddTurnAndPresenceToGamesAndPlayers < ActiveRecord::Migration[8.1]
  def change
    add_reference :games, :active_player, foreign_key: { to_table: :players, on_delete: :nullify }
    add_column :players, :online, :boolean, null: false, default: false
  end
end
