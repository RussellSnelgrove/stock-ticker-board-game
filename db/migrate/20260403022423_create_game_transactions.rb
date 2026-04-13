# typed: false
# frozen_string_literal: true

class CreateGameTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :game_transactions do |t|
      t.references :player, null: false, foreign_key: true
      t.references :game_stock, null: false, foreign_key: true
      t.string :transaction_type, null: false
      t.integer :quantity, null: false, default: 0
      t.integer :price_at_time, null: false
      t.integer :total_amount, null: false
      t.integer :turn_number, null: false

      t.timestamps
    end

    add_index :game_transactions, [ :player_id, :turn_number ]
    add_index :game_transactions, [ :game_stock_id, :turn_number ]
  end
end
