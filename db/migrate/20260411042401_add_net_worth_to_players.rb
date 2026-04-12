class AddNetWorthToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :net_worth, :integer
  end
end
