class CreateHoldings < ActiveRecord::Migration[8.1]
  def change
    create_table :holdings do |t|
      t.references :player, null: false, foreign_key: true
      t.references :game_stock, null: false, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
