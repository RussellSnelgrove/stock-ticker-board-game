# typed: false
# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      # UTF-8 column (default in PostgreSQL) to support emoji in chat.
      t.string :body, null: false, limit: 200

      t.timestamps
    end

    add_index :messages, [ :game_id, :created_at ]
  end
end
