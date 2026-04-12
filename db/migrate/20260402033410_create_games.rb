# typed: false
# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.string :invite_code, null: false
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "waiting"
      t.integer :current_turn, null: false, default: 0
      t.integer :duration, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :remaining_time
      t.integer :rolls_remaining_this_turn, null: false, default: 2

      t.timestamps
    end

    add_index :games, :invite_code, unique: true

    # Add the FK deferred from CreateGameStocks — games table now exists.
    add_foreign_key :game_stocks, :games
  end
end
