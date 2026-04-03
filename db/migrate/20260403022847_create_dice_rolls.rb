# typed: false
# frozen_string_literal: true

class CreateDiceRolls < ActiveRecord::Migration[8.1]
  def change
    create_table :dice_rolls do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :stock_rolled, null: false, foreign_key: { to_table: :stocks }
      t.integer :turn_number, null: false
      t.string :direction, null: false
      t.integer :amount, null: false

      t.timestamps
    end

    add_index :dice_rolls, [ :game_id, :turn_number ]
  end
end
