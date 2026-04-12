class AddFinalRankToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :final_rank, :integer
  end
end
