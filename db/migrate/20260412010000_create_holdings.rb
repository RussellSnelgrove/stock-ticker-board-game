# typed: false
# frozen_string_literal: true

class CreateHoldings < ActiveRecord::Migration[8.1]
  def change
    create_table :holdings do |t|
      t.references :player, null: false, foreign_key: true
      t.references :game_stock, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 0
      t.timestamps
    end
    add_index :holdings, [ :player_id, :game_stock_id ], unique: true
  end
end
