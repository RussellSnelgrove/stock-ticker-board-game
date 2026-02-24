class CreateGameTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :game_transactions do |t|
      t.references :player, null: false, foreign_key: true
      t.references :game_stock, null: false, foreign_key: true
      t.string :transaction_type, null: false
      t.integer :quantity, null: false
      t.integer :price_at_time, null: false
      t.integer :total_amount, null: false
      t.integer :turn_number, null: false

      t.timestamps
    end
  end
end
