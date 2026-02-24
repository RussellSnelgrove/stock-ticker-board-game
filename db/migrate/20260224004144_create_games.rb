class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :name
      t.string :invite_code
      t.string :status
      t.integer :current_turn
      t.integer :duration
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :remaining_time
      t.references :host, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :games, :invite_code
  end
end
