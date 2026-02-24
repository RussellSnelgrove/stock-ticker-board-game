# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :display_name, null: false
      t.timestamps null: false
    end
  end
end
