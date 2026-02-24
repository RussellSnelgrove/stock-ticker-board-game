class CreateGameStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :game_stocks do |t|
      t.references :game, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.integer :current_price

      t.timestamps
    end
  end
end
