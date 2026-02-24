class CreateDiceRolls < ActiveRecord::Migration[8.1]
  def change
    create_table :dice_rolls do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.integer :turn_number
      t.string :direction
      t.integer :amount

      t.timestamps
    end
  end
end
