# typed: false
# frozen_string_literal: true

class CreateGameStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :game_stocks do |t|
      # foreign_key: false for game — the games table doesn't exist yet.
      # A proper FK will be added when the Game model migration runs.
      t.references :game, null: false, foreign_key: false
      t.references :stock, null: false, foreign_key: true
      t.integer :current_price, null: false, default: 100

      t.timestamps
    end

    add_index :game_stocks, [ :game_id, :stock_id ], unique: true
  end
end
