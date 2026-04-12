# typed: false
# frozen_string_literal: true

class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :cash, null: false, default: 500_000
      t.string :status, null: false, default: "active"
      t.integer :turn_position, null: false

      t.timestamps
    end

    # A user can only join a given game once.
    add_index :players, [ :game_id, :user_id ], unique: true
    # Turn positions must be unique within a game.
    add_index :players, [ :game_id, :turn_position ], unique: true
  end
end
