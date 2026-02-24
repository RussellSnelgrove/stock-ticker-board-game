class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :cash
      t.string :status
      t.integer :turn_position

      t.timestamps
    end
  end
end
