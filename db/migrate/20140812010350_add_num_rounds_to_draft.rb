class AddNumRoundsToDraft < ActiveRecord::Migration
  def change
    add_column :drafts, :num_rounds, :integer
  end
end
