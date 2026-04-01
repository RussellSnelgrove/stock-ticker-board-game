# typed: false
# frozen_string_literal: true

class CreateStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :stocks do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :stocks, :name, unique: true
  end
end
