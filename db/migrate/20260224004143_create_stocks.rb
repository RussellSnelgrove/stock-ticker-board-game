class CreateStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :stocks do |t|
      t.string :name
      t.string :symbol
      t.string :color

      t.timestamps
    end
  end
end
